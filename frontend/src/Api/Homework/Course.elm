module Api.Homework.Course exposing (..)

import Api
import Api.Homework.User exposing (userDecoder)
import Date
import Http
import Json.Decode as Json
import Models exposing (Assignment, Course, User)
import Time


type alias MinimalCourse =
    { id : Int
    , subject : String
    , teacher : String
    }


dateDecoder : Json.Decoder Date.Date
dateDecoder =
    Json.string
        |> Json.andThen
            (\str ->
                case Date.fromIsoString str of
                    Ok res ->
                        Json.succeed res

                    Err e ->
                        Json.fail e
            )


assignmentDecoder : Json.Decoder Assignment
assignmentDecoder =
    Json.map6 Assignment
        (Json.field "id" Json.int)
        (Json.field "course" Json.int)
        (Json.field "creator" userDecoder)
        (Json.field "title" Json.string)
        (Json.field "description" (Json.nullable Json.string))
        (Json.field "dueDate" dateDecoder)


courseDecoder : Json.Decoder Course
courseDecoder =
    Json.map4 Course
        (Json.field "id" Json.int)
        (Json.field "subject" Json.string)
        (Json.field "teacher" Json.string)
        (Json.field "assignments" (Json.list assignmentDecoder))


minimalCourseDecoder : Json.Decoder MinimalCourse
minimalCourseDecoder =
    Json.map3 MinimalCourse
        (Json.field "id" Json.int)
        (Json.field "subject" Json.string)
        (Json.field "teacher" Json.string)


getActiveCourses : { onResponse : Api.Data (List Course) -> msg } -> Cmd msg
getActiveCourses options =
    Http.riskyRequest
        { body = Http.emptyBody
        , url = "http://localhost:5000/courses/active"
        , method = "GET"
        , expect = Api.expectJson options.onResponse (Json.at [ "content" ] (Json.list courseDecoder))
        , headers = []
        , timeout = Nothing
        , tracker = Nothing
        }


getMyCourses : { onResponse : Api.Data (List Course) -> msg } -> Cmd msg
getMyCourses options =
    Http.riskyRequest
        { body = Http.emptyBody
        , url = "http://localhost:5000/courses"
        , method = "GET"
        , expect = Api.expectJson options.onResponse (Json.at [ "content" ] (Json.list courseDecoder))
        , headers = []
        , timeout = Nothing
        , tracker = Nothing
        }


searchCourses : String -> { onResponse : Api.Data (List MinimalCourse) -> msg } -> Cmd msg
searchCourses searchterm options =
    Http.riskyRequest
        { body = Http.emptyBody
        , url = "http://localhost:5000/courses/search/" ++ searchterm
        , method = "GET"
        , expect = Api.expectJson options.onResponse (Json.at [ "content" ] (Json.list minimalCourseDecoder))
        , headers = []
        , timeout = Nothing
        , tracker = Nothing
        }
