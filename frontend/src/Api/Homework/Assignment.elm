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


assignmentEncoder : { title : String, courseId : Int, dueDate : Date.Date } -> Encode.Value
assignmentEncoder assignment =
    Encode.object
        [ ( "title", Encode.string assignment.title )
        , ( "course", Encode.int assignment.courseId )
        , ( "dueDate", Encode.string (dateEncoder assignment.dueDate) )
        ]


createAssignment : { title : String, courseId : Int, dueDate : Date.Date } -> { onResponse : Api.Data Assignment -> msg } -> Cmd msg
createAssignment assignment options =
    Http.riskyRequest
        { method = "POST"
        , url = apiAddress ++ "/assignment"
        , headers = []
        , body = Http.jsonBody (assignmentEncoder assignment)
        , expect = Api.expectJson options.onResponse (Json.at [ "content" ] assignmentDecoder)
        , timeout = Nothing
        , tracker = Nothing
        }


removeAssignment : Int -> { onResponse : Api.Data Assignment -> msg } -> Cmd msg
removeAssignment id options =
    Http.riskyRequest
        { method = "DELETE"
        , url = apiAddress ++ "/assignment?id=" ++ String.fromInt id
        , headers = []
        , body = Http.emptyBody
        , expect = Api.expectJson options.onResponse (Json.at [ "conetent" ] assignmentDecoder)
        , timeout = Nothing
        , tracker = Nothing
        }
