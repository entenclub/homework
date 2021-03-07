module Api exposing (Data(..), expectJson)

import Html.Attributes exposing (value)
import Http
import Json.Decode as Json
import Http

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
                    case Json.decodeString (Json.at ["errors"] (Json.list Json.string)) body of
                        Ok value ->
                            Err (BadStatus metadata.statusCode value)

                        Err err ->
                            Err (BadStatus metadata.statusCode ["an error occured."])

                Http.GoodStatus_ metadata body ->
                    case Json.decodeString (Json.at ["content"] decoder) body of
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
