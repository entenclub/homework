package routes

import (
	"bytes"
	"encoding/json"
	"github.com/3nt3/homework/logging"
	"net/http"
	"net/http/httptest"
	"testing"
)


func TestCreateUser(t *testing.T) {
	body, _ := json.Marshal(map[string]string{
		"username": "test1",
		"email": "test1@example.com",
		"password": "test123",
	})

	req, err := http.NewRequest("POST", "http://localhost:8000", bytes.NewBuffer(body))
	if err != nil {
		t.Errorf("error requesting: %v", err)
	}
	rr := httptest.NewRecorder()

	NewUser(rr, req)

	result := rr.Result()
	if result.StatusCode != http.StatusOK {
		t.Errorf("request failed with status code %d", result.StatusCode)
	}

	resp := apiResponse{}
	err = json.NewDecoder(result.Body).Decode(&resp)
	if err != nil {
		t.Errorf("error decoding body: %v", err)
	}

	if len(resp.Errors) > 0 {
		t.Errorf("request failed with errors: %v", resp.Errors)
	}

	logging.InfoLogger.Printf("user: %+v\n", resp.Content)
}

