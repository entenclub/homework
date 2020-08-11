module Shared exposing
    ( Assignment
    , Course
    , Device
    , DeviceClass(..)
    , Flags
    , Model
    , Msg
    , User
    , init
    , subscriptions
    , update
    , view
    )

import Api.Reddit.Listing exposing (new)
import Browser.Events
import Browser.Navigation exposing (Key)
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Spa.Document exposing (Document)
import Spa.Generated.Route as Route
import Time
import Url exposing (Url)



-- INIT


type alias Device =
    { class : DeviceClass
    , orientation : Orientation
    , width : Int
    , height : Int
    }


type DeviceClass
    = Phone
    | Tablet
    | Desktop


type Orientation
    = Portrait
    | Landscape


classifyDevice : { window | height : Int, width : Int } -> Device
classifyDevice options =
    if options.width < 450 then
        Device Phone Portrait options.width options.height

    else if options.width < 900 then
        Device Tablet Portrait options.width options.height

    else
        Device Desktop Landscape options.width options.height



-- model data types


type alias User =
    { id : Int
    , username : String
    , email : String
    , privilege : Int
    }


type alias Assignment =
    { id : Int
    , course : Int
    , creator : User
    , title : String
    , description : Maybe String
    , dueDate : Time.Posix
    }


type alias Course =
    { id : Int
    , subject : String
    , teacher : String
    , assignments : List Assignment
    }


type alias Flags =
    { width : Int, height : Int }


type alias Model =
    { url : Url
    , key : Key
    , user : Maybe User
    , device : Device
    }


init : Flags -> Url -> Key -> ( Model, Cmd Msg )
init flags url key =
    ( Model url key Nothing (classifyDevice { width = flags.width, height = flags.height })
    , Cmd.none
    )



-- UPDATE


type Msg
    = GotUser User
    | Logout
    | Resize Int Int


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotUser user ->
            ( { model | user = Just user }, Cmd.none )

        Logout ->
            ( { model | user = Nothing }, Cmd.none )

        Resize w h ->
            ( { model | device = classifyDevice { width = w, height = h } }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Browser.Events.onResize (\w h -> Resize w h)



-- VIEW


lighterGreyColor : Color
lighterGreyColor =
    rgb255 29 32 37


navBarElement : String -> String -> Element msg
navBarElement label url =
    el [] (link [] { label = text label, url = url })


navBarView : Maybe User -> Element msg
navBarView maybeUser =
    row
        [ Background.color lighterGreyColor
        , Font.color (rgb255 255 255 255)
        , Font.size 20
        , Font.family
            [ Font.typeface "Source Sans Pro"
            , Font.sansSerif
            ]
        , Font.semiBold
        , Element.paddingXY 60 30
        , spacing 40
        , width fill
        ]
        (case maybeUser of
            Just _ ->
                [ el [ alignLeft ] (navBarElement "Home" "/")
                , el [ alignRight ] (navBarElement "Dashboard" "/dashboard")
                ]

            Nothing ->
                [ el [ alignLeft ] (navBarElement "Home" "/")
                , el [ alignRight ] (navBarElement "Login" "/login")
                , el [ alignRight, Font.underline ] (navBarElement "Register" "/register")
                ]
        )


view :
    { page : Document msg, toMsg : Msg -> msg }
    -> Model
    -> Document msg
view { page, toMsg } model =
    { title = page.title
    , body =
        [ -- body
          navBarView model.user
        , column [ height fill, width fill ] page.body
        ]
    }
