module Api exposing (Data(..), HttpError(..), errorToString, expectJson, expectPlainJson)

import Html.Attributes exposing (value)
import Http
import Json.Decode as Json


type Data value
    = NotAsked
    | Loading
    | Failure HttpError
    | Success value


type HttpError
    = BadUrl String
    | Timeout
    | NetworkError
    | BadStatus Int (List String)
    | BadBody String


expectJson : (Data value -> msg) -> Json.Decoder value -> Http.Expect msg
expectJson toMsg =
    expectStringButItsJson (fromResult >> toMsg)


expectPlainJson : (Data value -> msg) -> Json.Decoder value -> Http.Expect msg
expectPlainJson toMsg =
    plainExpectStringButItsJson (fromResult >> toMsg)


expectStringButItsJson : (Result HttpError a -> msg) -> Json.Decoder a -> Http.Expect msg
expectStringButItsJson toMsg decoder =
    Http.expectStringResponse toMsg <|
        \response ->
            case response of
                Http.BadUrl_ url ->
                    Err (BadUrl url)

                Http.Timeout_ ->
                    Err Timeout

                Http.NetworkError_ ->
                    Err NetworkError

                Http.BadStatus_ metadata body ->
                    case Json.decodeString (Json.at [ "errors" ] (Json.list Json.string)) body of
                        Ok value ->
                            Err (BadStatus metadata.statusCode value)

                        Err _ ->
                            Err (BadStatus metadata.statusCode [ "an error occured." ])

                Http.GoodStatus_ _ body ->
                    case Json.decodeString (Json.at [ "content" ] decoder) body of
                        Ok value ->
                            Ok value

                        Err err ->
                            Err (BadBody (Json.errorToString err))


plainExpectStringButItsJson : (Result HttpError a -> msg) -> Json.Decoder a -> Http.Expect msg
plainExpectStringButItsJson toMsg decoder =
    Http.expectStringResponse toMsg <|
        \response ->
            case response of
                Http.BadUrl_ url ->
                    Err (BadUrl url)

                Http.Timeout_ ->
                    Err Timeout

                Http.NetworkError_ ->
                    Err NetworkError

                Http.BadStatus_ metadata _ ->
                    Err (BadStatus metadata.statusCode [ "an error occured." ])

                Http.GoodStatus_ _ body ->
                    case Json.decodeString decoder body of
                        Ok value ->
                            Ok value

                        Err err ->
                            Err (BadBody (Json.errorToString err))


fromResult : Result HttpError value -> Data value
fromResult result =
    case result of
        Ok value ->
            Success value

        Err reason ->
            Failure reason


errorToString : HttpError -> String
errorToString error =
    case error of
        BadStatus _ errors ->
            "an error occured: " ++ String.join "; " errors

        BadBody _ ->
            "an error occured"

        BadUrl _ ->
            "an error occured"

        NetworkError ->
            "unable to reach server"

        Timeout ->
            "request timed out"
