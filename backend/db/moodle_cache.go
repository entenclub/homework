package db

import (
	"encoding/json"
	"fmt"
	"github.com/3nt3/homework/structs"
	"github.com/segmentio/ksuid"
	"time"
)

func GetUserCachedCourses(user structs.User) ([]structs.CachedCourse, error) {
	var courses []structs.CachedCourse

	// get all cached moodle courses where moodle_url == the users moodle url and the userID == user.id
	query := "SELECT * FROM moodle_cache WHERE moodle_url = $1 AND user_id = $2"
	rows, err := database.Query(query, user.MoodleURL, user.ID)
	defer rows.Close()

	if err != nil {
		return courses, nil
	}

	// iterate through rows
	for rows.Next() {
		// create variables
		var newCourse structs.CachedCourse
		var jsonString string

		// populate variables
		err = rows.Scan(&newCourse.ID, &jsonString, &newCourse.MoodleURL, &newCourse.CachedAt, &newCourse.UserID)
		if err != nil {
			return nil, err
		}

		// decode json encoded course data
		if err = json.Unmarshal([]byte(jsonString), &newCourse.Course); err != nil {
			return nil, err
		}

		// get assignments
		newCourse.Course.Assignments, err = GetAssignmentsByCourse(int(newCourse.Course.ID.(float64)))
		if err != nil {
			return nil, err
		}

		// append to array
		courses = append(courses, newCourse)
	}

	// return
	return courses, nil
}

func DeleteCachedCourses(courses []structs.CachedCourse) error {
	ids := []ksuid.KSUID{}
	for _, cc := range courses {
		ids = append(ids, cc.ID)
	}

	statement := "DELETE FROM moodle_cache WHERE id IN $1"
	_, err := database.Exec(statement, ids)

	return err
}

func DeleteCachedCoursesPerUser(userID string) error {
	_, err := database.Exec("DELETE FROM moodle_cache WHERE user_id = $1", userID)
	return err
}

func CreateNewCacheObject(course structs.CachedCourse) error {
	jsonCourse, err := json.Marshal(course.Course)
	if err != nil {
		return err
	}

	_, err = database.Exec("INSERT INTO moodle_cache (id, course_json, moodle_url, cached_at, user_id) VALUES ($1, $2, $3, $4, $5)", ksuid.New().String(), string(jsonCourse), course.MoodleURL, time.Now(), course.UserID)
	return err
}

// SearchUserCourses returns all user courses matching a given search term
func SearchUserCourses(query string, user structs.User) ([]structs.CachedCourse, error) {
	rows, err := database.Query("SELECT * FROM moodle_cache WHERE to_tsvector('german', course_json) @@ to_tsquery('german', $1) OR lower(course_json) LIKE $2", query, fmt.Sprintf("%%%s%%", query))
	if err != nil {
		return nil, err
	}

	// create variables
	var courses []structs.CachedCourse

	for rows.Next() {
		var newCourse structs.CachedCourse
		var jsonString string

		// populate variables
		err = rows.Scan(&newCourse.ID, &jsonString, &newCourse.MoodleURL, &newCourse.CachedAt, &newCourse.UserID)
		if err != nil {
			return nil, err
		}

		// decode json encoded course data
		if err = json.Unmarshal([]byte(jsonString), &newCourse.Course); err != nil {
			return nil, err
		}

		// append to array
		courses = append(courses, newCourse)
	}

	return courses, nil
}