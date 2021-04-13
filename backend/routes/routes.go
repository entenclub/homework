package routes

import (
	"encoding/json"
	"github.com/3nt3/homework/db"
	"github.com/3nt3/homework/structs"
	"net/http"
)

type apiResponse struct {
	Content interface{} `json:"content"`
	Errors  []string    `json:"errors"`
}

func returnApiResponse(w http.ResponseWriter, response apiResponse, status int) error {
	w.WriteHeader(status)
	w.Header().Set("Content-Type", "application/json")

	if response.Errors == nil {
		response.Errors = []string{}
	}

	err := json.NewEncoder(w).Encode(response)

	return err
}

func getUserBySession(r *http.Request, getCourses bool) (structs.User, bool, error) {
	cookie, err := r.Cookie("hw_cookie_v2")
	if err != nil {
		return structs.User{}, false, err
	}

	sessionId := cookie.Value

	return db.GetUserBySession(sessionId, getCourses)
}

func HandleCORSPreflight(w http.ResponseWriter, r *http.Request) {
	w.Header().Add("Access-Control-Allow-Origin", r.Header.Get("Origin"))
	w.Header().Add("Access-Control-Allow-Credentials", "true")
	w.Header().Add("Access-Control-Allow-Headers", "Content-Type, x-requested-with, Origin")
	w.Header().Add("Access-Control-Allow-Methods", "GET, PUT, POST, DELETE, OPTIONS")
}
