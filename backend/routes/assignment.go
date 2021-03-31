package routes

import (
	"database/sql"
	"encoding/json"
	"github.com/3nt3/homework/db"
	"github.com/3nt3/homework/logging"
	"github.com/3nt3/homework/structs"
	"net/http"
	"strconv"
)

func CreateAssignment(w http.ResponseWriter, r *http.Request) {
	HandleCORSPreflight(w, r)
	user, authenticated, err := getUserBySession(r, false)

	if err != nil {
		logging.ErrorLogger.Printf("error getting user by session: %v\n", err)
		_ = returnApiResponse(w, apiResponse{
			Content: nil,
			Errors:  []string{"internal server error"},
		}, 500)
		return
	}

	if !authenticated {
		_ = returnApiResponse(w, apiResponse{
			Content: nil,
			Errors:  []string{"invalid session"},
		}, 401)
		return
	}

	var assignment structs.Assignment
	err = json.NewDecoder(r.Body).Decode(&assignment)
	if err != nil {
		logging.WarningLogger.Printf("error decoding: %v\n", err)
		_ = returnApiResponse(w, apiResponse{
			Content: nil,
			Errors:  []string{"bad request"},
		}, http.StatusBadRequest)
		return
	}

	assignment.User = user

	assignment, err = db.CreateAssignment(assignment)
	if err != nil {
		logging.ErrorLogger.Printf("error creating assignment: %v\n", err)
		_ = returnApiResponse(w, apiResponse{
			Content: nil,
			Errors:  []string{"internal server error"},
		}, http.StatusInternalServerError)
		return
	}

	_ = returnApiResponse(w, apiResponse{
		Content: assignment.GetClean(),
		Errors:  []string{},
	}, http.StatusOK)
}

func DeleteAssignment(w http.ResponseWriter, r *http.Request) {
	HandleCORSPreflight(w, r)

	id := r.URL.Query().Get("id")
	if id == "" {
		_ = returnApiResponse(w, apiResponse{
			Content: nil,
			Errors:  []string{"bad request"},
		}, http.StatusBadRequest)
		return
	}

	user, authenticated, err := getUserBySession(r, false)

	if err != nil {
		logging.ErrorLogger.Printf("error getting user by session: %v\n", err)
		_ = returnApiResponse(w, apiResponse{
			Content: nil,
			Errors:  []string{"internal server error"},
		}, 500)
		return
	}

	if !authenticated {
		_ = returnApiResponse(w, apiResponse{
			Content: nil,
			Errors:  []string{"invalid session"},
		}, 401)
		return
	}

	assignment, err := db.GetAssignmentByID(id)
	if err != nil {
		if err == sql.ErrNoRows {
			_ = returnApiResponse(w, apiResponse{
				Content: nil,
				Errors:  []string{"not found"},
			}, http.StatusNotFound)
			return
		}

		_ = returnApiResponse(w, apiResponse{
			Content: nil,
			Errors:  []string{"internal server error"},
		}, http.StatusInternalServerError)
		return
	}

	if assignment.User.ID != user.ID {
		_ = returnApiResponse(w, apiResponse{
			Content: nil,
			Errors:  []string{"you are not the creator of this assignment"},
		}, http.StatusForbidden)
		return
	}

	err = db.DeleteAssignment(assignment.UID.String())
	if err != nil {
		_ = returnApiResponse(w, apiResponse{
			Content: nil,
			Errors:  []string{"internal server error"},
		}, http.StatusInternalServerError)
		return
	}

	_ = returnApiResponse(w, apiResponse{
		Content: assignment.GetClean(),
		Errors:  []string{},
	}, http.StatusOK)
}

func GetAssignments(w http.ResponseWriter, r *http.Request) {
	HandleCORSPreflight(w, r)

	user, authenticated, err := getUserBySession(r, false)
	if err != nil {
		logging.ErrorLogger.Printf("error getting user by session: %v\n", err)
		_ = returnApiResponse(w, apiResponse{
			Content: nil,
			Errors:  []string{"internal server error"},
		}, 500)
		return
	}

	if !authenticated {
		_ = returnApiResponse(w, apiResponse{
			Content: nil,
			Errors:  []string{"invalid session"},
		}, 401)
		return
	}

	var days int
	daysString := r.URL.Query().Get("days")
	if daysString == "" {
		days = -1
	} else {
		days, err = strconv.Atoi(daysString)
		if err != nil {
			_ = returnApiResponse(w, apiResponse{
				Content: nil,
				Errors:  []string{"?days is not a valid integer"},
			}, 400)
			return
		}
	}

	assignments, err := db.GetAssignments(user, days)
	if err != nil && err != sql.ErrNoRows {
		logging.ErrorLogger.Printf("error getting assignments session: %v\n", err)
		_ = returnApiResponse(w, apiResponse{
			Content: nil,
			Errors:  []string{"internal server error"},
		}, 500)
		return
	}

	if assignments == nil {
		assignments = make([]structs.Assignment, 0)
	}

	var cleanAssignments []structs.CleanAssignment
	for _, a := range assignments {
		cleanAssignments = append(cleanAssignments, a.GetClean())
	}

	_ = returnApiResponse(w, apiResponse{
		Content: assignments,
	}, 200)
}
