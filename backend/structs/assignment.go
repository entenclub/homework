package structs

import (
	"fmt"
	"strings"
	"time"
)

func (j *JSONDate) UnmarshalJSON(b []byte) error {
	s := strings.Trim(string(b), "\"")
	t, err := time.Parse("2-1-2006", s)
	if err != nil {
		return err
	}
	*j = JSONDate(t)
	return nil
}

func (j JSONDate) MarshalJSON() ([]byte, error) {
	// logically, the date has to be encoded differently than it is decoded
	// makes total sense lol
	return []byte(fmt.Sprintf("\"%s\"", time.Time(j).Format("2006-01-02"))), nil
}

