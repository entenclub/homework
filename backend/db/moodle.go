package db

import (
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"github.com/3nt3/homework/logging"
	"github.com/3nt3/homework/structs"
	"github.com/segmentio/ksuid"
	"net/http"
	"strconv"
	"time"
)

type moodleCourse struct {
	ID          int    `json:"id"`
	DisplayName string `json:"displayname"`
	FullName    string `json:"fullname"`
}

func GetMoodleUserCourses(user structs.User) ([]structs.Course, error) {
	baseURL := user.MoodleURL
	token := user.MoodleToken
	var courses []structs.Course

	if baseURL == "" || token == "" {
		return courses, errors.New("no token or moodle url was provided")
	}

	/*
		$ curl "https://your.site.com/moodle/webservice/rest/server.php?wstoken=...&wsfunction=...&moodlewsrestformat=json"
	*/

	cacheObjs, err := GetUserCachedCourses(user)
	if err != nil {
		if err == sql.ErrNoRows {
			cacheObjs = []structs.CachedCourse{}
		} else {
			return nil, err
		}
	}

	expired := false
	for _, cacheObj := range cacheObjs {
		// if the cached object is older than (7 * 24 hours = 7 days), set as expired
		if time.Since(cacheObj.CachedAt).Hours() > (7 * 24) {
			expired = true
			break
		}
	}

	getFreshData := false

	if len(cacheObjs) > 0 {
		if expired {
			// delete all queried courses
			err = DeleteCachedCourses(cacheObjs)
			if err != nil {
				return nil, err
			}

			// clear array
			cacheObjs = []structs.CachedCourse{}
			getFreshData = true
		} else {
			for _, cacheObj := range cacheObjs {
				if time.Since(cacheObj.CachedAt).Seconds() > 120 {
					break
				}
			}
		}
	} else {
		// since there is no usable cache, request data from moodle
		getFreshData = true
	}

	if getFreshData {
		resp, err := getUserCoursesReq(user.MoodleURL, user.MoodleToken, user.MoodleUserID)
		if err != nil {
			return nil, err
		}

		if resp.StatusCode != http.StatusOK {
			return nil, fmt.Errorf("http request not ok. status %d", resp.StatusCode)
		}

		var mCourses []moodleCourse
		err = json.NewDecoder(resp.Body).Decode(&mCourses)
		if err != nil {
			return nil, err
		}

		for _, mCourse := range mCourses {
			assignments, err := GetAssignmentsByCourse(mCourse.ID)
			if err != nil {
				if err != sql.ErrNoRows {
					return nil, err
				}
			}

			if assignments == nil {
				assignments = make([]structs.Assignment, 0)
			}

			var newCachedCourse structs.CachedCourse = structs.CachedCourse{
				Course: structs.Course{
					ID:          mCourse.ID,
					Name:        mCourse.DisplayName,
					FromMoodle:  true,
					Assignments: assignments,
					User:        user.ID,
				},
				MoodleURL: user.MoodleURL,
				UserID:    user.ID,
			}

			cacheObjs = append(cacheObjs, newCachedCourse)
		}
	}

	// update cache
	go func() {
		if err := updateCache(baseURL, user.MoodleToken, user.ID, user.MoodleUserID); err != nil {
			logging.WarningLogger.Printf("error updating course cache: %v\n", err)
		}
	}()

	for _, cc := range cacheObjs {
		courses = append(courses, cc.Course)
	}

	return courses, nil
}

func getUserCoursesReq(baseURL string, token string, moodleUserID int) (*http.Response, error) {
	r, err := http.NewRequest(http.MethodGet, baseURL+"/webservice/rest/server.php", nil)
	if err != nil {
		return nil, err
	}

	q := r.URL.Query()
	q.Add("wstoken", token)
	q.Add("wsfunction", "core_enrol_get_users_courses")

	q.Add("userid", strconv.Itoa(moodleUserID))
	q.Add("moodlewsrestformat", "json")
	r.URL.RawQuery = q.Encode()

	client := &http.Client{}
	return client.Do(r)
}

func updateCache(baseURL string, token string, userID ksuid.KSUID, moodleUserID int) error {
	resp, err := getUserCoursesReq(baseURL, token, moodleUserID)
	if err != nil {
		return err
	}

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("http request not ok. status %d", resp.StatusCode)
	}

	var mCourses []moodleCourse
	var cacheObjs []structs.CachedCourse
	err = json.NewDecoder(resp.Body).Decode(&mCourses)

	now := time.Now()

	// delete old cache
	err = DeleteCachedCoursesPerUser(userID.String())
	if err != nil {
		return err
	}

	for _, mCourse := range mCourses {
		if err != nil {
			return err
		}

		var newCachedCourse structs.CachedCourse = structs.CachedCourse{
			Course: structs.Course{
				ID:          mCourse.ID,
				Name:        mCourse.DisplayName,
				FromMoodle:  true,
				User:        userID,
			},
			MoodleURL: baseURL,
			UserID:    userID,
			CachedAt: now,
		}

		cacheObjs = append(cacheObjs, newCachedCourse)
	}


	for _, cc := range cacheObjs {
		err = CreateNewCacheObject(cc)
		if err != nil {
			return err
		}
	}

	return nil
}
