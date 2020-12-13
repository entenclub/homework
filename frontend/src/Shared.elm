port module Shared exposing
    ( Device
    , DeviceClass(..)
    , Flags
    , Model
    , Msg
    , init
    , subscriptions
    , update
    , view
    )

import Api
import Api.Homework.User exposing (getUserFromSession, logout)
import Browser.Events
import Browser.Navigation exposing (Key)
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events
import Element.Font as Font
import Http
import Models exposing (User)
import Spa.Document exposing (Document)
import Spa.Generated.Route as Route
import Styling.Colors exposing (redColor)
import Time
import Url exposing (Url)



-- PORTS


port deleteCookie : () -> Cmd msg



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
    if options.width < 900 then
        Device Phone Portrait options.width options.height

    else if options.width < 1400 then
        Device Tablet Portrait options.width options.height

    else
        Device Desktop Landscape options.width options.height


type alias Flags =
    { width : Int
    , height : Int
    }


type alias Model =
    { url : Url
    , key : Key
    , user : Maybe User
    , device : Device
    }


init : Flags -> Url -> Key -> ( Model, Cmd Msg )
init flags url key =
    ( Model url key Nothing (classifyDevice { width = flags.width, height = flags.height })
    , getUserFromSession { onResponse = GotUser }
    )



-- UPDATE


type Msg
    = GotUser (Api.Data User)
    | Logout
    | Resize Int Int
    | GotLogoutData (Result Http.Error ())


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotUser userData ->
            case userData of
                Api.Success user ->
                    ( { model | user = Just user }, Cmd.none )

                _ ->
                    ( { model | user = Nothing }, Cmd.none )

        Logout ->
            ( { model | user = Nothing }, logout { onResponse = GotLogoutData } )

        Resize w h ->
            ( { model | device = classifyDevice { width = w, height = h } }, Cmd.none )

        GotLogoutData _ ->
            ( model, deleteCookie () )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Browser.Events.onResize (\w h -> Resize w h)



-- VIEW


lighterGreyColor : Color
lighterGreyColor =
    rgb255 29 32 37


navBarElement : Element msg -> String -> Element msg
navBarElement label url =
    el [] (link [] { label = label, url = url })


viewHomeButton =
    row [ spacing 7 ]
        [ text "beta.hausis.3nt3.de"
        , el
            [ padding 3
            , Background.color redColor
            , Font.color
                (rgb 1 1 1)
            , Border.rounded 5
            ]
            (text "v0.3")
        ]


navBarView : Device -> Maybe User -> { toMsg : Msg -> msg } -> Element msg
navBarView device maybeUser options =
    (case device.class of
        Phone ->
            column

        _ ->
            row
    )
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
        , height shrink
        , Font.center
        ]
        (case maybeUser of
            Just _ ->
                [ el
                    ([ centerY
                     ]
                        ++ (case device.class of
                                Phone ->
                                    [ alignBottom
                                    , paddingEach { bottom = 20, top = 0, left = 0, right = 0 }
                                    ]

                                _ ->
                                    [ alignLeft ]
                           )
                    )
                    (navBarElement
                        viewHomeButton
                        "/"
                    )
                , el
                    [ case device.class of
                        Phone ->
                            alignBottom

                        _ ->
                            alignRight
                    ]
                    (navBarElement (text "dashboard") "/dashboard")
                , el
                    [ case device.class of
                        Phone ->
                            alignBottom

                        _ ->
                            alignRight
                    , Events.onClick (options.toMsg Logout)
                    ]
                    (navBarElement (text "logout") "/")
                ]

            Nothing ->
                [ el
                    [ case device.class of
                        Phone ->
                            alignTop

                        _ ->
                            alignLeft
                    , centerY
                    ]
                    (navBarElement
                        viewHomeButton
                        "/"
                    )
                , el
                    [ case device.class of
                        Phone ->
                            alignBottom

                        _ ->
                            alignRight
                    ]
                    (navBarElement (text "login") "/login")
                , el
                    [ case device.class of
                        Desktop ->
                            alignLeft

                        _ ->
                            alignBottom
                    , Font.underline
                    ]
                    (navBarElement (text "register") "/register")
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
          navBarView model.device model.user { toMsg = toMsg }
        , column [ height fill, width fill ] page.body
        ]
    }
