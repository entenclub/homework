package routes

import (
	"database/sql"
	"github.com/3nt3/homework/db"
	"github.com/3nt3/homework/logging"
	"github.com/3nt3/homework/structs"
	"github.com/gorilla/mux"
	"net/http"
	"time"
)

// TODO: return all courses with assignments whose due dates lie in the future
func GetActiveCourses(w http.ResponseWriter, r *http.Request) {
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

	courses, err := db.GetMoodleUserCourses(user)
	if err != nil {
		if err.Error() == "no token or moodle url was provided" {
			logging.InfoLogger.Printf("no moodle access configured for user %s\n", user.ID.String())

			_ = returnApiResponse(w, apiResponse{
				Content: []string{},
				Errors:  []string{},
			}, 200)
			return
		}
		logging.ErrorLogger.Printf("error: %v\n", err)
	}

	var filteredCourses []structs.Course
	for _, c := range courses {
		var filteredAssignments []structs.Assignment
		for _, a := range c.Assignments {
			if time.Time(a.DueDate).Truncate(24 * time.Hour).After(time.Now().Truncate(24 * time.Hour)) || time.Time(a.DueDate).Truncate(24 *time.Hour).Equal(time.Now().Truncate(24 * time.Hour)) {
				filteredAssignments = append(filteredAssignments, a)
			}
		}

		if len(filteredAssignments) > 0 {
			c.Assignments = filteredAssignments
			filteredCourses = append(filteredCourses, c)
		}
	}

	var cleanCourses = make([]structs.CleanCourse, 0)
	for _, c := range filteredCourses {
		cleanCourses = append(cleanCourses, c.GetClean())
	}

	_ = returnApiResponse(w, apiResponse{
		Content: cleanCourses,
		Errors:  []string{},
	}, 200)
}

func SearchCourses(w http.ResponseWriter, r *http.Request) {
	HandleCORSPreflight(w, r)

	user, authenticated, err := getUserBySession(r, false)
	if !authenticated {
		if err != nil {
			logging.ErrorLogger.Printf("error getting user by session: %v\n", err)
		}
		_ = returnApiResponse(w, apiResponse{
			Content: nil,
			Errors:  []string{"invalid session"},
		}, 401)
		return
	}

	searchterm, ok := mux.Vars(r)["searchterm"]
	if !ok {
		_ = returnApiResponse(w, apiResponse{Content: nil, Errors: []string{"no searchterm provided"}}, http.StatusBadRequest)
		return
	}

	matchingCourses, err := db.SearchUserCourses(searchterm, user)
	if err != nil {
		if err == sql.ErrNoRows {
			_ = returnApiResponse(w, apiResponse{Content: []interface{}{}, Errors: []string{}}, http.StatusOK)
		} else {
			logging.ErrorLogger.Printf("an error occured searching courses: %v", err)
			_ = returnApiResponse(w, apiResponse{Content: nil, Errors: []string{"internal server error"}}, http.StatusInternalServerError)
		}
		return
	}

	cleanCourses := []structs.CleanCourse{}
	for _, c := range matchingCourses {
		cleanCourses = append(cleanCourses, c.GetClean())
	}

	_ = returnApiResponse(w, apiResponse{
		Content: cleanCourses,
		Errors:  []string{},
	}, 200)
	return
}

// TODO
func GetAllCourses(w http.ResponseWriter, r *http.Request) {
	HandleCORSPreflight(w, r)

}
