package routes

import (
	"bytes"
	"encoding/json"
	"github.com/3nt3/homework/logging"
	"github.com/3nt3/homework/structs"
	"net/http"
	"net/http/httptest"
	"os"
	"testing"
	"time"
)

func TestCreateAssignment(t *testing.T) {
	a := structs.Assignment{
		Title:      "test assignment",
		DueDate:    time.Date(2021, 11, 16, 0, 0, 0, 0, time.UTC),
		Course:     123,
		FromMoodle: false,
	}
	body, _ := json.Marshal(a)

	req, err := http.NewRequest("POST", "http://localhost:8000/assignment", bytes.NewBuffer(body))
	req.AddCookie(&http.Cookie{Name: "hw_cookie_v2", Value: os.Getenv("HW_SESSION_COOKIE")})
	if err != nil {
		t.Errorf("error requesting: %v", err)
	}

	arr := httptest.NewRecorder()

	CreateAssignment(arr, req)

	aResult := arr.Result()
	if aResult.StatusCode != http.StatusOK {
		t.Errorf("request failed with status code %d", aResult.StatusCode)
	}

	aResp := apiResponse{}
	err = json.NewDecoder(aResult.Body).Decode(&aResp)
	if err != nil {
		t.Errorf("error decoding body: %v", err)
	}

	logging.InfoLogger.Printf("assignment")
}

func TestDeleteAssignment(t *testing.T) {
	// create assignment
	a := structs.Assignment{
		Title:      "test assignment",
		DueDate:    time.Date(2021, 11, 16, 0, 0, 0, 0, time.UTC),
		Course:     123,
		FromMoodle: false,
	}
	body, _ := json.Marshal(a)

	req, err := http.NewRequest("POST", "http://localhost:8000/assignment", bytes.NewBuffer(body))
	req.AddCookie(&http.Cookie{Name: "hw_cookie_v2", Value: os.Getenv("HW_SESSION_COOKIE")})
	if err != nil {
		t.Errorf("error requesting: %v", err)
	}

	arr := httptest.NewRecorder()

	CreateAssignment(arr, req)

	aResult := arr.Result()

	aResp := apiResponse{}
	err = json.NewDecoder(aResult.Body).Decode(&aResp)
	if err != nil {
		t.Errorf("error decoding body: %v", err)
	}

	if aResult.StatusCode != http.StatusOK {
		t.Errorf("request failed with status code %d %v", aResult.StatusCode, aResp.Errors)
	}

	assignmentJson, err := json.Marshal(aResp.Content)
	if err != nil {
		return
	}

	var respA structs.Assignment
	err = json.Unmarshal(assignmentJson, &respA)
	if err != nil {
		t.Errorf("error: %v\n", err)
	}

	req, err = http.NewRequest("DELETE", "http://localhost:8000/assignment?id=" + respA.UID.String(), bytes.NewBuffer(body))
	req.AddCookie(&http.Cookie{Name: "hw_cookie_v2", Value: os.Getenv("HW_SESSION_COOKIE")})
	if err != nil {
		t.Errorf("error requesting: %v\n", err)
	}

	logging.InfoLogger.Printf("assignment: %+v\n", respA)

	rr := httptest.NewRecorder()

	DeleteAssignment(rr, req)

	result := rr.Result()
	if result.StatusCode != http.StatusOK {
		t.Errorf("request failed with status code %d", result.StatusCode)
	}

	resp := apiResponse{}
	err = json.NewDecoder(result.Body).Decode(&resp)
	if err != nil {
		t.Errorf("error decoding body: %v", err)
	}

	if aResult.StatusCode != http.StatusOK {
		t.Errorf("request failed with status code %d %v", result.StatusCode, resp.Errors)
	}
}