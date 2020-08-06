module Pages.Posts exposing (Model, Msg, Params, page)

import Api
import Api.Reddit.Listing exposing (Listing)
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Http
import Spa.Document exposing (Document)
import Spa.Page as Page exposing (Page)
import Spa.Url exposing (Url)


page : Page Params Model Msg
page =
    Page.element
        { view = view
        , update = update
        , init = init
        , subscriptions = subscriptions
        }


type alias Params =
    ()


type alias Model =
    { listings : Api.Data (List Listing) }


init : Url Params -> ( Model, Cmd Msg )
init url =
    ( Model Api.Loading
    , Api.Reddit.Listing.hot { onResponse = GotHotListings }
    )


type Msg
    = GotHotListings (Api.Data (List Listing))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotHotListings data ->
            ( { model | listings = data }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


view : Model -> Document Msg
view model =
    { title = "Posts"
    , body =
        [ el [] (viewListings model.listings) ]
    }


viewListings : Api.Data (List Listing) -> Element msg
viewListings data =
    case data of
        Api.NotAsked ->
            text "Not asked"

        Api.Loading ->
            text "Loading"

        Api.Failure reason ->
            case reason of
                Http.BadStatus status ->
                    text (String.fromInt status)

                Http.BadUrl sth ->
                    text sth

                Http.BadBody str ->
                    text str

                _ ->
                    text "error"

        Api.Success listings ->
            column []
                (List.map viewListing listings)


viewListing : Listing -> Element msg
viewListing listing =
    el [] (text listing.title)
