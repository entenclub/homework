module Api.Reddit.Listing exposing (Listing, hot, new, top)

import Api
import Http
import Json.Decode as Json


type alias Listing =
    { title : String
    , author : String
    , url : String
    }


decoder : Json.Decoder Listing
decoder =
    Json.map3 Listing
        (Json.field "title" Json.string)
        (Json.field "author_fullname" Json.string)
        (Json.field "url" Json.string)



-- ENDPOINTS


hot : { onResponse : Api.Data (List Listing) -> msg } -> Cmd msg
hot =
    listings "hot"


top : { onResponse : Api.Data (List Listing) -> msg } -> Cmd msg
top =
    listings "top"


new : { onResponse : Api.Data (List Listing) -> msg } -> Cmd msg
new =
    listings "new"


listings : String -> { onResponse : Api.Data (List Listing) -> msg } -> Cmd msg
listings endpoint options =
    Http.get
        { url = "https://api.reddit.com/r/elm/" ++ endpoint
        , expect =
            Api.expectJson options.onResponse
                (Json.at [ "data", "children" ] (Json.list decoder))
        }
