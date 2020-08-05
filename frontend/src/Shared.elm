module Shared exposing
    ( Flags
    , Model
    , Msg
    , init
    , subscriptions
    , update
    , view
    )

import Browser.Navigation exposing (Key)
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Spa.Document exposing (Document)
import Spa.Generated.Route as Route
import Url exposing (Url)



-- INIT


type alias Flags =
    ()


type alias Model =
    { url : Url
    , key : Key
    }


init : Flags -> Url -> Key -> ( Model, Cmd Msg )
init flags url key =
    ( Model url key
    , Cmd.none
    )



-- UPDATE


type Msg
    = ReplaceMe


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ReplaceMe ->
            ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


navBarElement : String -> String -> Element msg
navBarElement label url =
    el [] (link [] { label = text label, url = url })


navBarView : Element msg
navBarView =
    let
        horizontalPadding =
            40

        verticalPadding =
            30
    in
    row
        [ Background.color (rgb255 61 61 61)
        , Font.color (rgb255 255 255 255)
        , Font.size 24
        , Font.family
            [ Font.typeface "Noto Serif"
            , Font.serif
            ]
        , paddingEach
            { left = horizontalPadding
            , right = horizontalPadding
            , top = verticalPadding
            , bottom = verticalPadding
            }
        , spacing 20
        , width fill
        ]
        [ el [ alignLeft ] (navBarElement "Home" "/")
        , el [ alignRight ] (navBarElement "Login" "/login")
        , el [ alignRight, Font.underline ] (navBarElement "Register" "/register")
        ]


view :
    { page : Document msg, toMsg : Msg -> msg }
    -> Model
    -> Document msg
view { page, toMsg } model =
    { title = page.title
    , body =
        [ -- body
          navBarView
        , column [ height fill, width fill ] page.body
        ]
    }
