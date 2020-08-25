module Api.Moodle.Moodle exposing (getSiteName)

import Api
import Http exposing (jsonBody)
import Json.Decode as Json
import Json.Encode as Encode



--https://gym-haan.lms.schulon.org/lib/ajax/service-nologin.php?args=%5B%7B%22index%22%3A0,%22methodname%22%3A%22tool_mobile_get_public_config%22,%22args%22%3A%5B%5D%7D%5D


decoder : Json.Decoder String
decoder =
    Json.at [ "content", "sitename" ] Json.string


encoder : String -> Encode.Value
encoder url =
    Encode.object
        [ ( "url", Encode.string url ) ]


getSiteName : String -> { onResponse : Api.Data String -> msg } -> Cmd msg
getSiteName url options =
    Http.post
        { url = "http://localhost:5000/moodle/get-school-info"
        , expect = Api.expectJson options.onResponse decoder
        , body = jsonBody (encoder url)
        }