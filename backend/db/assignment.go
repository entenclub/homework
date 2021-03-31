package db

import (
	"database/sql"
	"github.com/3nt3/homework/structs"
	"github.com/segmentio/ksuid"
	"strconv"
	"time"
)

func CreateAssignment(assignment structs.Assignment) (structs.Assignment, error) {
	id := ksuid.New()
	_, err := database.Exec("INSERT INTO assignments (id, content, course_id, due_date, creator_id, created_at, from_moodle) VALUES ($1, $2, $3, $4, $5, $6, $7)", id.String(), assignment.Title, assignment.Course, time.Time(assignment.DueDate), assignment.User.ID, assignment.Created, assignment.FromMoodle)

	newAssignment := assignment
	newAssignment.UID = id

	return newAssignment, err
}

func GetAssignmentByID(id string) (structs.Assignment, error) {
	row := database.QueryRow("SELECT * FROM assignments WHERE id = $1", id)

	var a structs.Assignment
	if row.Err() != nil {
		return a, row.Err()
	}

	var creatorID string
	var dueDateT time.Time

	err := row.Scan(&a.UID, &a.Title, &a.Course, &dueDateT, &creatorID, &a.Created, &a.FromMoodle)
	if err != nil {
		return a, err
	}

	creator, err := GetUserById(creatorID, false)
	a.User = creator
	a.DueDate = structs.JSONDate(dueDateT)

	return a, err
}

func DeleteAssignment(id string) error {
	_, err := database.Exec("DELETE FROM assignments WHERE id = $1", id)
	return err
}

func GetAssignmentsByCourse(courseID int) ([]structs.Assignment, error) {
	rows, err := database.Query("SELECT * FROM assignments WHERE course_id = $1", courseID)

	if err != nil {
		return nil, err
	}

	var assignments []structs.Assignment
	for rows.Next() {
		var a structs.Assignment

		var creatorID string
		var dueDateT time.Time

		err := rows.Scan(&a.UID, &a.Title, &a.Course, &dueDateT, &creatorID, &a.Created, &a.FromMoodle)
		if err != nil {
			return nil, err
		}

		a.DueDate = structs.JSONDate(dueDateT)

		creator, err := GetUserById(creatorID, false)
		a.User = creator
		if err != nil {
			return nil, err
		}

		assignments = append(assignments, a)
	}

	return assignments, nil
}

// GetAssignments returns all assignments that were created by user in the given time frame specified by maxDays.
// If maxDays is -1, time is ignored and all assignments are returned
func GetAssignments(user structs.User, maxDays int) ([]structs.Assignment, error) {
	var rows *sql.Rows
	var err error
	if maxDays == -1 {
		rows, err = database.Query("SELECT * FROM assignments WHERE creator_id = $1", user.ID.String())
	} else {
		rows, err = database.Query("SELECT * FROM assignments WHERE creator_id = $1 AND assignments.due_date >= NOW() - ($2 || ' days')::INTERVAL", user.ID.String(), strconv.Itoa(maxDays))
	}

	if err != nil {
		return nil, err
	}

	var assignments []structs.Assignment
	for rows.Next() {
		var a structs.Assignment

		var creatorID string
		var dueDateT time.Time
		err := rows.Scan(&a.UID, &a.Title, &a.Course, &dueDateT, &creatorID, &a.Created, &a.FromMoodle)
		if err != nil {
			return nil, err
		}

		creator, err := GetUserById(creatorID, false)
		a.User = creator
		a.DueDate = structs.JSONDate(dueDateT)
		if err != nil {
			return nil, err
		}

		assignments = append(assignments, a)
	}
	defer rows.Close()

	return assignments, nil
}