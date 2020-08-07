module Api.Homework.User exposing (User, getUser, usernameTaken)

import Api
import Http
import Json.Decode as Json


type Privilege
    = Normal
    | Admin


type alias Credentials =
    { username : String
    , password : String
    }


type alias User =
    { id : Int
    , username : String
    , email : String
    , privilege : Int
    }


userDecoder : Json.Decoder User
userDecoder =
    Json.map3 User
        (Json.field "id" Json.int)
        (Json.field "username" Json.string)
        (Json.field "email" Json.string)
        (Json.field "privilege" Json.int)


getUserById : Int -> { onResponse : Api.Data User -> msg } -> Cmd msg
getUserById id options =
    Http.get
        { url = "http://localhost:5000/user/" ++ String.fromInt id
        , expect = Api.expectJson options.onRespnse (Json.at [ "content" ]) userDecoder
        }


usernameTaken : String -> { onResponse : Api.Data Bool -> msg } -> Cmd msg
usernameTaken username options =
    Http.get
        { url = "http://localhost:5000/username-taken/" ++ username
        , expect = Api.expectJson options.onRespnse (Json.at [ "content" ] Json.bool)
        }


login : Credentials -> { onResponse : Api.Data User -> msg } -> Cmd msg
login credentials options =
    Http.post
        { url = "http://localhost:5000/user/login"
        , body = Http.jsonBody credentials
        , expect = Api.expectJson options.onResponse userDecoder
        }
