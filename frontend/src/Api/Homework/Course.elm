module Api.Homework.Course exposing (..)

import Api
import Api.Homework.User exposing (userDecoder)
import Date
import Http exposing (jsonBody)
import Json.Decode as Json
import Json.Encode as Encode
import Models exposing (Assignment, Course, User)
import Time


type alias MinimalCourse =
    { id : Int
    , subject : String
    , teacher : String
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
    Json.map6 Assignment
        (Json.field "id" Json.int)
        (Json.field "course" Json.int)
        (Json.field "creator" userDecoder)
        (Json.field "title" Json.string)
        (Json.field "description" (Json.nullable Json.string))
        (Json.field "dueDate" dateDecoder)


courseDecoder : Json.Decoder Course
courseDecoder =
    Json.map5 Course
        (Json.field "id" Json.int)
        (Json.field "subject" Json.string)
        (Json.field "teacher" Json.string)
        (Json.field "assignments" (Json.list assignmentDecoder))
        (Json.field "fromMoodle" Json.bool)


minimalCourseDecoder : Json.Decoder MinimalCourse
minimalCourseDecoder =
    Json.map4 MinimalCourse
        (Json.field "id" Json.int)
        (Json.field "subject" Json.string)
        (Json.field "teacher" Json.string)
        (Json.field "fromMoodle" (Json.nullable Json.bool)
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
        , url = "https://api.hausis.3nt3.de/courses/active"
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
        , url = "https://api.hausis.3nt3.de/courses"
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
        , url = "https://api.hausis.3nt3.de/courses/search/" ++ searchterm
        , method = "GET"
        , expect = Api.expectJson options.onResponse (Json.at [ "content" ] (Json.list minimalCourseDecoder))
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
        , url = "https://api.hausis.3nt3.de/courses"
        , method = "POST"
        , expect = Api.expectJson options.onResponse (Json.at [ "content" ] courseDecoder)
        , headers = []
        , timeout = Nothing
        , tracker = Nothing
        }


enrollInCourse : Int -> { onResponse : Api.Data User -> msg } -> Cmd msg
enrollInCourse id options =
    Http.riskyRequest
        { body = Http.emptyBody
        , url = "https://api.hausis.3nt3.de/courses/" ++ String.fromInt id ++ "/enroll"
        , expect = Api.expectJson options.onResponse (Json.at [ "content" ] userDecoder)
        , method = "POST"
        , headers = []
        , timeout = Nothing
        , tracker = Nothing
        }
