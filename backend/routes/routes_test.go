package routes

import (
	"bytes"
	"encoding/json"
	"github.com/3nt3/homework/db"
	"github.com/3nt3/homework/logging"
	"net/http"
	"net/http/httptest"
	"os"
	"testing"
)

func setup() {
	logging.InitLoggers()

	// initialize database
	err := db.InitDatabase(true)
	if err != nil {
		logging.ErrorLogger.Fatalf("error initializing db: %v\n", err)
	}

	// create user
	body, _ := json.Marshal(map[string]string{
		"username": "test",
		"email": "test@example.com",
		"password": "test123",
	})

	req, err := http.NewRequest("POST", "http://localhost:8000", bytes.NewBuffer(body))
	if err != nil {
		logging.ErrorLogger.Fatalf("error requesting: %v", err)
	}
	rr := httptest.NewRecorder()

	NewUser(rr, req)

	result := rr.Result()
	if result.StatusCode != http.StatusOK {
		logging.ErrorLogger.Fatalf("request failed with status code %d", result.StatusCode)
	}

	os.Setenv("HW_SESSION_COOKIE", result.Cookies()[0].Value)
}

func shutdown() {
	_ = db.DropTables()
}

func TestMain(m *testing.M) {
	setup()
	m.Run()
	shutdown()
	os.Exit(0)
}
