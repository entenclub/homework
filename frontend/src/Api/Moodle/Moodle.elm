module Api.Moodle.Moodle exposing (authenticateUser, getSiteName)

import Api
import Api.Api exposing (apiAddress)
import Api.Homework.User exposing (userDecoder)
import Http exposing (jsonBody)
import Json.Decode as Json
import Json.Encode as Encode
import Models exposing (User)



--https://gym-haan.lms.schulon.org/lib/ajax/service-nologin.php?args=%5B%7B%22index%22%3A0,%22methodname%22%3A%22tool_mobile_get_public_config%22,%22args%22%3A%5B%5D%7D%5D


decoder : Json.Decoder String
decoder =
    Json.at [ "sitename" ] Json.string


encoder : String -> Encode.Value
encoder url =
    Encode.object
        [ ( "url", Encode.string url ) ]


getSiteName : String -> { onResponse : Api.Data String -> msg } -> Cmd msg
getSiteName url options =
    Http.post
        { url = "https://api.hausis.3nt3.de/moodle/get-school-info"
        , expect = Api.expectJson options.onResponse decoder
        , body = jsonBody (encoder url)
        }


credentialsEncoder : String -> String -> String -> Encode.Value
credentialsEncoder url username password =
    Encode.object
        [ ( "url", Encode.string url )
        , ( "username", Encode.string username )
        , ( "password", Encode.string password )
        ]


authenticateUser : String -> String -> String -> { onResponse : Api.Data User -> msg } -> Cmd msg
authenticateUser url username password options =
    Http.riskyRequest
        { method = "POST"
        , body = jsonBody (credentialsEncoder url username password)
        , headers = []
        , tracker = Nothing
        , url = apiAddress ++ "/moodle/authenticate"
        , timeout = Nothing
        , expect = Api.expectJson options.onResponse userDecoder
        }
