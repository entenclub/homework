package main

import (
	"fmt"
	"github.com/3nt3/homework/db"
	"github.com/3nt3/homework/logging"
	"github.com/3nt3/homework/routes"
	"github.com/gorilla/mux"
	"net/http"
	"os"
	"os/signal"
	"syscall"
)


func main() {
	logging.InitLoggers()


        port := 8005

        err := db.InitDatabase(false)

	if err != nil {
		logging.ErrorLogger.Printf("error connecting to db: %v\n", err)
		return
	}

	InterruptHandler()

	r := mux.NewRouter()
	r.Methods("OPTIONS").HandlerFunc(routes.HandleCORSPreflight)

	// /user routes
	r.HandleFunc("/user/register", routes.NewUser).Methods("POST")
	r.HandleFunc("/user", routes.GetUser).Methods("GET")
	r.HandleFunc("/user/{id}", routes.GetUserById).Methods("GET")
	r.HandleFunc("/user/login", routes.Login).Methods("POST")

	// misc
	r.HandleFunc("/username-taken/{username}", routes.UsernameTaken)
	r.HandleFunc("/email-taken/{email}", routes.EmailTaken)

	// /assignment routes
	r.HandleFunc("/assignment", routes.CreateAssignment).Methods("POST")
	r.HandleFunc("/assignment", routes.DeleteAssignment).Methods("DELETE")
	r.HandleFunc("/assignments", routes.GetAssignments).Methods("GET")

	// /courses routes
	r.HandleFunc("/courses/active", routes.GetActiveCourses)
	r.HandleFunc("/courses/search/{searchterm}", routes.SearchCourses)

	// /moodle routes
	r.HandleFunc("/moodle/authenticate", routes.MoodleAuthenticate).Methods("POST")
	r.HandleFunc("/moodle/get-school-info", routes.MoodleGetSchoolInfo).Methods("POST")
	// TODO: /moodle/get-courses


	logging.InfoLogger.Printf("started server on port %d", port)
	logging.ErrorLogger.Fatalln(http.ListenAndServe(fmt.Sprintf(":%d", port), r).Error())
}

func InterruptHandler() {
	c := make(chan os.Signal)

	signal.Notify(c, syscall.SIGINT)
	signal.Notify(c, syscall.SIGTERM)
	go func() {
		<-c
		logging.InfoLogger.Printf("closing db connection...")
		db.CloseConnection()
		logging.InfoLogger.Printf("done!")

		logging.InfoLogger.Printf("exiting...")
		os.Exit(0)
	}()
}
