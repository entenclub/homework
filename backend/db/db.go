package db

import (
	"database/sql"
	"fmt"
	"github.com/3nt3/homework/logging"
	_ "github.com/lib/pq"
	"os"
)

const (
	host     = "db"
	port     = 5432
	user     = "homework"
	dbname   = "homework"
)

var database *sql.DB

func InitDatabase(testing bool) error {
	logging.InfoLogger.Printf("connecting to database...\n")

	password := os.Getenv("DBPASSWORD")

	var psqlconn string
	if !testing {
		_, err := os.Stat("/.dockerenv")
		logging.InfoLogger.Printf("err: %v", err)
		if os.IsNotExist(err) {
			psqlconn = fmt.Sprintf("host=%s port=%d user=%s password=%s dbname=%s sslmode=disable", "localhost", port, user, password, dbname)
		} else {
			psqlconn = fmt.Sprintf("host=%s port=%d user=%s password=%s dbname=%s sslmode=disable", host, port, user, password, dbname)
		}
	} else {
		psqlconn = "host=localhost port=5432 user=homework_testing password=testing dbname=homework_testing sslmode=disable"
	}

	foo, err := sql.Open("postgres", psqlconn)
	if err != nil {
		return err
	}
	database = foo

	err = database.Ping()
	if err != nil {
		return err
	}

	logging.InfoLogger.Printf("connection to database successful\n")

	if testing {
		logging.InfoLogger.Printf("dropping tables /bc testing")
		_ = DropTables()
	}

	logging.InfoLogger.Printf("creating tables...\n")
	err = initializeTables()
	if err != nil {
		return err
	}
	logging.InfoLogger.Printf("tables created successfully")

	return nil
}

func initializeTables() error {
	_, err := database.Exec("CREATE TABLE IF NOT EXISTS users (id text PRIMARY KEY UNIQUE, username text UNIQUE, email text UNIQUE, password_hash text, created_at timestamp, permission int, courses_json text, moodle_url text, moodle_token text, moodle_user_id int)")
	if err != nil {
		return err
	}

	_, err = database.Exec("CREATE TABLE IF NOT EXISTS assignments (id text PRIMARY KEY UNIQUE, content text, course_id int, due_date timestamp, creator_id text, created_at timestamp, from_moodle bool)")
	if err != nil {
		return err
	}

	_, err = database.Exec("CREATE TABLE IF NOT EXISTS sessions (uid text PRIMARY KEY UNIQUE, user_id text, created_at timestamp)")
	if err != nil {
		return err
	}

	_, err = database.Exec("CREATE TABLE IF NOT EXISTS moodle_cache (id text PRIMARY KEY UNIQUE, course_json text, moodle_url text, cached_at timestamp, user_id text);")
	if err != nil {
		return err
	}

	return nil
}

func DropTables() error {
	_, err := database.Exec("DROP TABLE users, sessions, assignments, moodle_cache;")
	return err
}

func CloseConnection() {
	_ = database.Close()
}