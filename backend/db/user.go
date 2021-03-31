package db

import (
	"database/sql"
	"encoding/json"
	"github.com/3nt3/homework/structs"
	"github.com/segmentio/ksuid"
	"golang.org/x/crypto/bcrypt"
	"time"
)

func NewUser(username string, email string, password string) (structs.User, error) {
	id := ksuid.New()

	hash, err := hashPassword(password)
	if err != nil {
		return structs.User{}, err
	}

	now := time.Now()
	_, err = database.Exec("insert into users (id, username, email, password_hash, permission, created_at, courses_json, moodle_url, moodle_user_id, moodle_token) VALUES ($1, $2, $3, $4, 0, $5, '[]', '', -1, '');", id.String(), username, email, hash, now)
	if err != nil {
		return structs.User{}, err
	}

	return structs.User{
		ID:           id,
		Username:     username,
		Email:        email,
		PasswordHash: hash,
		Created:      now,
		Privilege:    0,
	}, nil
}

func GetUserByUsername(username string, getCourses bool) (structs.User, error) {
	row := database.QueryRow("select * from users where username = $1;", username)
	if row.Err() != nil {
		return structs.User{}, row.Err()
	}

	return scanUserRow(row, getCourses)
}

/*
func GetUserByEmail(email string ) (structs.User, error) {
	row := database.QueryRow("select * from users where email = $1;", email)
	if row.Err() != nil {
		return structs.User{}, row.Err()
	}

	var user structs.User
	err := row.Scan(&user.ID, &user.Username, &user.Email, &user.PasswordHash, &user.Created, &user.Privilege)
	if err != nil {
		return structs.User{}, err
	}

	return user, nil
}

*/

func GetUserById(id string, getCourses bool) (structs.User, error) {
	row := database.QueryRow("SELECT * FROM users WHERE id = $1", id)
	if row.Err() != nil {
		return structs.User{}, row.Err()
	}

	return scanUserRow(row, getCourses)
}

func Authenticate(username string, password string) (structs.User, bool, error) {
	// get user by username
	user, err := GetUserByUsername(username, false)
	if err != nil {
		if err == sql.ErrNoRows {
			return user, false, nil
		}
		return user, false, err
	}

	// check password
	err = bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(password))
	if err != nil {
		// if incorrect password, return
		if err == bcrypt.ErrMismatchedHashAndPassword {
			return structs.User{}, false, nil
		}

		// if other error return error
		return structs.User{}, false, err
	}

	// if no error, return authenticated
	return user, true, nil
}

func GetUserBySession(sessionId string, getCourses bool) (structs.User, bool, error) {
	row := database.QueryRow("SELECT * FROM sessions WHERE uid = $1", sessionId)
	if row.Err() != nil {
		return structs.User{}, false, row.Err()
	}

	session := structs.Session{}
	err := row.Scan(&session.UID, &session.UserID, &session.Created)
	if err != nil {
		return structs.User{}, false, err
	}

	oldestPossible := time.Now().AddDate(0, 0, -structs.MaxSessionAge)
	if !session.Created.After(oldestPossible) {
		return structs.User{}, false, nil
	}

	user, err := GetUserById(session.UserID.String(), getCourses)

	go deleteOldSessions(structs.MaxSessionAge)

	return user, true, err
}

func hashPassword(password string) (string, error) {
	bytes, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	return string(bytes), err
}

func UpdateMoodleData(user structs.User, moodleURL string, token string, moodleUserID int, getCourses bool) (structs.User, error) {
	_, err := database.Exec("UPDATE users SET moodle_url = $1, moodle_token = $2, moodle_user_id = $3 WHERE id = $4", moodleURL, token, moodleUserID, user.ID.String())

	if err != nil {
		return structs.User{}, err
	}

	// return user
	return GetUserById(user.ID.String(), getCourses)
}

func scanUserRow(row *sql.Row, getCourses bool) (structs.User, error) {
	var courseIds []int
	var coursesJson string
	var user structs.User

	err := row.Scan(&user.ID, &user.Username, &user.Email, &user.PasswordHash, &user.Created, &user.Privilege, &coursesJson, &user.MoodleURL, &user.MoodleToken, &user.MoodleUserID)
	if err != nil {
		return structs.User{}, err
	}

	if err = json.Unmarshal([]byte(coursesJson), &courseIds); err != nil {
		return structs.User{}, err
	}

	if user.MoodleToken != "" && user.MoodleURL != "" && getCourses {
		user.Courses, err = GetMoodleUserCourses(user)
		if err != nil {
			return user, err
		}
	}

	return user, nil
}

// UsernameTaken returns true if there is a row with the username provided as an argument and false if there isn't
func UsernameTaken(username string) (bool, error) {
	row := database.QueryRow("select exists(select 1 from users where username = $1)", username)
	if row.Err() != nil {
		return false, row.Err()
	}

	var exists bool
	if err := row.Scan(&exists); err != nil {
		return false, err
	}

	return exists, nil
}
// EmailTaken returns true if there is a row with the email provided as an argument and false if there isn't
func EmailTaken(email string) (bool, error) {
	row := database.QueryRow("select exists(select 1 from users where email = $1)", email)
	if row.Err() != nil {
		return false, row.Err()
	}

	var exists bool
	if err := row.Scan(&exists); err != nil {
		return false, err
	}

	return exists, nil
}
