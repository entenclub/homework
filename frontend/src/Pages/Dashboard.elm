module Pages.Dashboard exposing (Model, Msg, Params, page)

import Api exposing (Data(..))
import Api.Homework.User exposing (getUserFromSession)
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Http
import Shared exposing (User)
import Spa.Document exposing (Document)
import Spa.Page as Page exposing (Page)
import Spa.Url exposing (Url)
import Utils.Route
import Utils.Vh exposing (vh, vw)


type alias Params =
    ()


type alias Model =
    { userData : Api.Data User
    , device : Shared.Device
    }


type Msg
    = GotUserData (Api.Data User)
    | Refresh


page : Page Params Model Msg
page =
    Page.application
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        , load = load
        , save = save
        }


init : Shared.Model -> Url Params -> ( Model, Cmd Msg )
init shared url =
    ( { userData = NotAsked, device = shared.device }, getUserFromSession { onResponse = GotUserData } )


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


load : Shared.Model -> Model -> ( Model, Cmd msg )
load shared model =
    ( { model | device = shared.device }, Cmd.none )


save : Model -> Shared.Model -> Shared.Model
save model shared =
    shared


borderRadius : Int
borderRadius =
    20


blueColor : Color
blueColor =
    rgb255 45 156 252


lighterGreyColor : Color
lighterGreyColor =
    rgb255 29 32 37


darkGreyColor : Color
darkGreyColor =
    rgb255 26 28 33


view : Model -> Document Msg
view model =
    { title = "dashboard"
    , body =
        [ (case model.device.class of
            Shared.Desktop ->
                wrappedRow

            _ ->
                column
          )
            [ width fill
            , height fill
            , Font.family
                [ Font.typeface "Source Sans Pro"
                , Font.sansSerif
                ]
            , Font.color (rgb 1 1 1)
            , padding 30
            , Background.color darkGreyColor
            ]
            [ -- sidebar
              viewSidebar model

            -- content
            , column
                [ width
                    (case model.device.class of
                        Shared.Phone ->
                            fill

                        _ ->
                            fillPortion 4
                    )
                , height fill
                , Background.color darkGreyColor
                ]
                [ text " " ]
            ]
        ]
    }


viewUser : Api.Data User -> Element msg
viewUser data =
    case data of
        Success user ->
            viewUserComponent user

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


viewSidebar : Model -> Element msg
viewSidebar model =
    column
        [ width
            (case model.device.class of
                Shared.Desktop ->
                    fillPortion 1 |> minimum 300

                _ ->
                    fill
            )
        , height fill
        , Background.color lighterGreyColor
        , padding 40
        , Border.rounded borderRadius
        ]
        [ viewUser model.userData ]


viewUserComponent : User -> Element msg
viewUserComponent user =
    column [ centerX, spacing 10 ]
        [ el
            [ Border.rounded 50
            , width (px 100)
            , height (px 100)
            , Background.color blueColor
            , Font.color (rgb 1 1 1)
            , centerX
            ]
            (el
                [ centerX
                , centerY
                , Font.size 60
                , spacing 100
                ]
                (text
                    (String.toUpper
                        (String.slice
                            0
                            1
                            user.username
                        )
                    )
                )
            )
        , el
            [ Font.size 30
            , Font.semiBold
            , Font.color (rgb 1 1 1)
            , centerX
            , Font.center
            ]
            (if String.length user.username > 12 then
                text ("Hey, " ++ String.slice 0 12 user.username ++ "...")

             else
                text ("Hey, " ++ user.username)
            )
        , el [ centerX ]
            (if user.privilege == 1 then
                text "Administrator"

             else
                Element.none
            )
        ]
