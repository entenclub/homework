module Api.Homework.UsernameTaken exposing (..)

import Api
import Http
import Json.Decode as Json


usernameTaken : String -> { onResponse : Api.Data Bool -> msg } -> Cmd msg
usernameTaken username options =
    Http.get
        { url = "http://localhost:5000/username-taken/" ++ username
        , expect = Api.expectJson options.onResponse (Json.at [ "content" ] Json.bool)
        }
