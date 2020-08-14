module Api.Homework.Assignment exposing (createAssignment)

import Api
import Api.Homework.Course exposing (assignmentDecoder)
import Date
import Http
import Json.Decode as Json
import Json.Encode as Encode
import Models exposing (Assignment)


dateEncoder : Date.Date -> String
dateEncoder date =
    Date.format "y-M-d" date


assignmentEncoder : Assignment -> Encode.Value
assignmentEncoder assignment =
    Encode.object
        [ ( "title", Encode.string assignment.title )
        , ( "course", Encode.int assignment.courseId )
        , ( "dueDate", Encode.string (dateEncoder assignment.dueDate) )
        ]


createAssignment : Assignment -> { onRespose : Api.Data Assignment -> msg } -> Cmd msg
createAssignment assignment options =
    Http.riskyRequest
        { method = "POST"
        , url = "http://localhost:5000/assignment"
        , headers = []
        , body = Http.jsonBody (assignmentEncoder assignment)
        , expect = Api.expectJson options.onRespose (Json.at [ "content" ] assignmentDecoder)
        , timeout = Nothing
        , tracker = Nothing
        }
