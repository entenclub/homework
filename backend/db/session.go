package db

import (
	"github.com/3nt3/homework/logging"
	"github.com/3nt3/homework/structs"
	"github.com/segmentio/ksuid"
	"time"
)

func deleteOldSessions(maxAgeDays int) {
	oldestPossible := time.Now().AddDate(0, 0, -maxAgeDays)

	_, err := database.Exec("DELETE FROM sessions WHERE created_at < $1", oldestPossible)
	if err != nil {
		logging.ErrorLogger.Printf("error deleting old sessions: %v\n", err)
		return
	}
}

func NewSession(user structs.User) (structs.Session, error) {
	now := time.Now()
	uid := ksuid.New()

	_, err := database.Exec("INSERT INTO sessions (uid, user_id, created_at) VALUES ($1, $2, $3)", uid.String(), user.ID.String(), now)

	go deleteOldSessions(structs.MaxSessionAge)

	return structs.Session{
		UID:     uid,
		UserID:  user.ID,
		Created: now,
	}, err
}

func GetSessionById(uid string) (structs.Session, error) {
	row := database.QueryRow("SELECT * FROM sessions WHERE uid = $1", uid)
	if row.Err() != nil {
		return structs.Session{}, row.Err()
	}

	var session structs.Session
	if err := row.Scan(&session.UID, &session.UserID, &session.Created); err != nil {
		return structs.Session{}, err
	}

	return session, nil
}