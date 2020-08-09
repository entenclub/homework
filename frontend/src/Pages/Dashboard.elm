module Pages.Dashboard exposing (Model, Msg, Params, page)

import Api exposing (Data(..))
import Api.Homework.User exposing (User, getUserFromSession)
import Element exposing (..)
import Http
import Spa.Document exposing (Document)
import Spa.Page as Page exposing (Page)
import Spa.Url exposing (Url)
import Utils.Route
import Http


type alias Params =
    ()


type alias Model =
    { userData : Api.Data User }


type Msg
    = GotUserData (Api.Data User)
    | Refresh


page : Page Params Model Msg
page =
    Page.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }


init : Url Params -> ( Model, Cmd Msg )
init url =
    ( { userData = NotAsked }, getUserFromSession { onResponse = GotUserData } )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotUserData data ->
            ( { model | userData = data }, Cmd.none )

        Refresh ->
            ( model, getUserFromSession { onResponse = GotUserData } )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


view : Model -> Document Msg
view model =
    { title = "dashboard"
    , body =
        [ viewUser model.userData ]
    }


viewUser : Api.Data User -> Element msg
viewUser data =
    case data of
        Success user ->
            text user.username

        Loading ->
            text "Loading..."

        Failure error ->
            case error of
                Http.BadStatus status ->
                    text ("bad status: " ++ String.fromInt status)

                Http.BadBody err ->
                    text ("bad body: " ++ err)

                Http.BadUrl err ->
                    text ("bad url: " ++ err)

                Http.NetworkError ->
                    text "network error"

                _ ->
                    text "other error"

        NotAsked ->
            Element.none
