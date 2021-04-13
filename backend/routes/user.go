package routes

import (
	"database/sql"
	"encoding/json"
	"github.com/3nt3/homework/db"
	"github.com/3nt3/homework/logging"
	"github.com/3nt3/homework/structs"
	"github.com/gorilla/mux"
	"net/http"
	"strings"
)

func NewUser(w http.ResponseWriter, r *http.Request) {
	HandleCORSPreflight(w, r)

	var userData map[string]string
	err := json.NewDecoder(r.Body).Decode(&userData)
	if err != nil {
		logging.WarningLogger.Printf("error decoding request: %v\n", err)
		_ = returnApiResponse(w, apiResponse{Content: nil, Errors: []string{"invalid request"}}, 400)
		return
	}

	username, ok := userData["username"]
	if !ok {
		logging.WarningLogger.Printf("error decoding request: field 'username' does not exist\n")
		_ = returnApiResponse(w, apiResponse{Content: nil, Errors: []string{"invalid request"}}, 400)
		return
	}

	email, ok := userData["email"]
	if !ok {
		logging.WarningLogger.Printf("error decoding request: field 'email' does not exist\n")
		_ = returnApiResponse(w, apiResponse{Content: nil, Errors: []string{"invalid request"}}, 400)
		return
	}

	password, ok := userData["username"]
	if !ok {
		logging.WarningLogger.Printf("error decoding request: field 'password' does not exist\n")
		_ = returnApiResponse(w, apiResponse{Content: nil, Errors: []string{"invalid request"}}, 400)
		return
	}

	user, err := db.NewUser(username, email, password)
	if err != nil {
		var responseCode int
		if strings.Contains(err.Error(), "duplicate key value violates unique constraint") {
			if strings.Contains(err.Error(), "email") {
				_ = returnApiResponse(w, apiResponse{Content: nil, Errors: []string{"email already in use"}}, http.StatusBadRequest)
				return
			}
			if strings.Contains(err.Error(), "username") {
				_ = returnApiResponse(w, apiResponse{Content: nil, Errors: []string{"username already in use"}}, http.StatusBadRequest)
				return
			}
		}
		logging.ErrorLogger.Printf("error creating new user: %v\n", err)
		_ = returnApiResponse(w, apiResponse{Content: nil, Errors: []string{"internal server error"}}, responseCode)
		return
	}

	session, err := db.NewSession(user)
	if err != nil {
		logging.ErrorLogger.Printf("error creating new session: %v\n", err)
		_ = returnApiResponse(w, apiResponse{Content: nil, Errors: []string{"internal server error"}}, 500)
		return
	}

	sessionCookie := http.Cookie{
		Name:   "hw_cookie_v2",
		Value:  session.UID.String(),
		MaxAge: structs.MaxSessionAge * 24 * 60 * 60,
		Path:   "/",
	}

	http.SetCookie(w, &sessionCookie)

	_ = returnApiResponse(w, apiResponse{Content: user.GetClean(), Errors: []string{}}, 200)
}

func GetUserById(w http.ResponseWriter, r *http.Request) {
	HandleCORSPreflight(w, r)

	id, ok := mux.Vars(r)["id"]
	if !ok {
		logging.WarningLogger.Printf("no id specified\n")
		_ = returnApiResponse(w, apiResponse{Content: nil, Errors: []string{"invalid request"}}, 400)
		return
	}

	user, err := db.GetUserById(id, false)
	if err != nil {
		logging.ErrorLogger.Printf("error fetching user from db: %v\n", err)
		if err != sql.ErrNoRows {
			_ = returnApiResponse(w, apiResponse{Content: nil, Errors: []string{"internal server error"}}, 500)
		} else {
			_ = returnApiResponse(w, apiResponse{Content: nil, Errors: []string{"user does not exist"}}, 404)
		}
		return
	}

	_ = returnApiResponse(w, apiResponse{Content: user.GetClean(), Errors: []string{}}, 200)
}

func Login(w http.ResponseWriter, r *http.Request) {
	HandleCORSPreflight(w, r)

	var userData map[string]string

	err := json.NewDecoder(r.Body).Decode(&userData)
	if err != nil {
		logging.WarningLogger.Printf("error decoding request: %v\n", err)
		_ = returnApiResponse(w, apiResponse{Content: nil, Errors: []string{"invalid request"}}, 400)
		return
	}

	username, ok := userData["username"]
	if !ok {
		logging.WarningLogger.Printf("error decoding request: field 'username' does not exist\n")
		_ = returnApiResponse(w, apiResponse{Content: nil, Errors: []string{"invalid request"}}, 400)
		return
	}

	password, ok := userData["username"]
	if !ok {
		logging.WarningLogger.Printf("error decoding request: field 'password' does not exist\n")
		_ = returnApiResponse(w, apiResponse{Content: nil, Errors: []string{"invalid request"}}, 400)
		return
	}

	user, authenticated, err := db.Authenticate(username, password)
	if err != nil {
		logging.ErrorLogger.Printf("error authenticating: %v\n", err)
		return
	}

	if !authenticated {
		logging.InfoLogger.Printf("authentication failed, wrong password")
		_ = returnApiResponse(w, apiResponse{Content: nil, Errors: []string{"wrong password"}}, 401)
		return
	}

	session, err := db.NewSession(user)
	if err != nil {
		logging.ErrorLogger.Printf("error creating new session: %v\n", err)
		_ = returnApiResponse(w, apiResponse{Content: nil, Errors: []string{"internal server error"}}, 500)
		return
	}

	sessionCookie := http.Cookie{
		Name:   "hw_cookie_v2",
		Value:  session.UID.String(),
		MaxAge: structs.MaxSessionAge * 24 * 60 * 60,
		Path:   "/",
	}

	http.SetCookie(w, &sessionCookie)
	_ = returnApiResponse(w, apiResponse{Content: user.GetClean(), Errors: []string{}}, 200)
}

func GetUser(w http.ResponseWriter, r *http.Request) {
	HandleCORSPreflight(w, r)

	user, authenticated, err := getUserBySession(r, true)
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

	_ = returnApiResponse(w, apiResponse{Content: user.GetClean(), Errors: []string{}}, 200)
}

func UsernameTaken(w http.ResponseWriter, r *http.Request) {
	HandleCORSPreflight(w, r)

	username, ok := mux.Vars(r)["username"]
	if !ok {
		_ = returnApiResponse(w, apiResponse{
			Errors:  []string{"no username provided"},
		}, 400)
		return
	}

	taken, err := db.UsernameTaken(username)
	if err != nil {
		_ = returnApiResponse(w, apiResponse{
			Errors:  []string{"internal server error"},
		}, 500)
	}

	_ = returnApiResponse(w, apiResponse{Content: taken, Errors: []string{}}, 200)
}

func EmailTaken(w http.ResponseWriter, r *http.Request) {
	HandleCORSPreflight(w, r)

	email, ok := mux.Vars(r)["email"]
	if !ok {
		_ = returnApiResponse(w, apiResponse{
			Errors: []string{"no username provided"},
		}, 400)
		return
	}

	taken, err := db.EmailTaken(email)
	if err != nil {
		_ = returnApiResponse(w, apiResponse{
			Errors: []string{"internal server error"},
		}, 500)
	}

	_ = returnApiResponse(w, apiResponse{Content: taken, Errors: []string{}}, 200)
}