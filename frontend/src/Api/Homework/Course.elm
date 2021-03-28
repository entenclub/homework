module Api.Homework.Course exposing (..)

import Api
import Api.Api exposing (apiAddress)
import Api.Homework.User exposing (userDecoder)
import Date
import Http exposing (jsonBody)
import Json.Decode as Json
import Json.Encode as Encode
import Models exposing (Assignment, Course, User)
import Time


type alias MinimalCourse =
    { id : Int
    , name : String
    , fromMoodle : Bool
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
    Json.map7 Assignment
        (Json.field "id" Json.string)
        (Json.field "course" Json.int)
        (Json.field "user" userDecoder)
        (Json.field "title" Json.string)
        (Json.field "description" (Json.nullable Json.string))
        (Json.field "due_date" dateDecoder)
        (Json.field "from_moodle" Json.bool)


courseDecoder : Json.Decoder Course
courseDecoder =
    Json.map5 Course
        (Json.field "id" Json.int)
        (Json.field "name" Json.string)
        (Json.field "assignments" (Json.list assignmentDecoder))
        (Json.field "from_moodle" Json.bool)
        (Json.field "user" Json.string)


minimalCourseDecoder : Json.Decoder MinimalCourse
minimalCourseDecoder =
    Json.map3 MinimalCourse
        (Json.field "id" Json.int)
        (Json.field "name" Json.string)
        (Json.field "from_moodle" (Json.nullable Json.bool)
            |> Json.andThen
                (\maybeBool ->
                    case maybeBool of
                        Just bool ->
                            Json.succeed bool

                        Nothing ->
                            Json.succeed False
                )
        )


getActiveCourses : { onResponse : Api.Data (List Course) -> msg } -> Cmd msg
getActiveCourses options =
    Http.riskyRequest
        { body = Http.emptyBody
        , url = apiAddress ++ "/courses/active"
        , method = "GET"
        , expect = Api.expectJson options.onResponse  (Json.list courseDecoder)
        , headers = []
        , timeout = Nothing
        , tracker = Nothing
        }


getMyCourses : { onResponse : Api.Data (List Course) -> msg } -> Cmd msg
getMyCourses options =
    Http.riskyRequest
        { body = Http.emptyBody
        , url = apiAddress ++ "/courses"
        , method = "GET"
        , expect = Api.expectJson options.onResponse (Json.list courseDecoder)
        , headers = []
        , timeout = Nothing
        , tracker = Nothing
        }


searchCourses : String -> { onResponse : Api.Data (List MinimalCourse) -> msg } -> Cmd msg
searchCourses searchterm options =
    Http.riskyRequest
        { body = Http.emptyBody
        , url = apiAddress ++ "/courses/search/" ++ searchterm
        , method = "GET"
        , expect = Api.expectJson options.onResponse (Json.list minimalCourseDecoder)
        , headers = []
        , timeout = Nothing
        , tracker = Nothing
        }


createCourse : String -> String -> { onResponse : Api.Data Course -> msg } -> Cmd msg
createCourse subject teacher options =
    Http.riskyRequest
        { body =
            Http.jsonBody
                (Encode.object
                    [ ( "subject", Encode.string subject )
                    , ( "teacher", Encode.string teacher )
                    ]
                )
        , url = apiAddress ++ "/courses"
        , method = "POST"
        , expect = Api.expectJson options.onResponse  courseDecoder
        , headers = []
        , timeout = Nothing
        , tracker = Nothing
        }


enrollInCourse : Int -> { onResponse : Api.Data User -> msg } -> Cmd msg
enrollInCourse id options =
    Http.riskyRequest
        { body = Http.emptyBody
        , url = apiAddress ++ "/courses/" ++ String.fromInt id ++ "/enroll"
        , expect = Api.expectJson options.onResponse userDecoder
        , method = "POST"
        , headers = []
        , timeout = Nothing
        , tracker = Nothing
        }
