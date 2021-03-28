module Api.Homework.Assignment exposing (createAssignment, removeAssignment)

import Api
import Api.Api exposing (apiAddress)
import Api.Homework.Course exposing (assignmentDecoder)
import Date
import Http
import Json.Decode as Json
import Json.Encode as Encode
import Models exposing (Assignment)


dateEncoder : Date.Date -> String
dateEncoder date =
    Date.format "d-M-y" date


assignmentEncoder : { title : String, courseId : Int, dueDate : Date.Date, fromMoodle : Bool } -> Encode.Value
assignmentEncoder assignment =
    Encode.object
        [ ( "title", Encode.string assignment.title )
        , ( "course", Encode.int assignment.courseId )
        , ( "due_date", Encode.string (dateEncoder assignment.dueDate) )
        , ( "from_moodle", Encode.bool assignment.fromMoodle )
        ]


createAssignment : { title : String, courseId : Int, dueDate : Date.Date, fromMoodle : Bool } -> { onResponse : Api.Data Assignment -> msg } -> Cmd msg
createAssignment assignment options =
    Http.riskyRequest
        { method = "POST"
        , url = apiAddress ++ "/assignment"
        , headers = []
        , body = Http.jsonBody (assignmentEncoder assignment)
        , expect = Api.expectJson options.onResponse assignmentDecoder
        , timeout = Nothing
        , tracker = Nothing
        }


removeAssignment : String -> { onResponse : Api.Data Assignment -> msg } -> Cmd msg
removeAssignment id options =
    Http.riskyRequest
        { method = "DELETE"
        , url = apiAddress ++ "/assignment?id=" ++ id
        , headers = []
        , body = Http.emptyBody
        , expect = Api.expectJson options.onResponse assignmentDecoder
        , timeout = Nothing
        , tracker = Nothing
        }
