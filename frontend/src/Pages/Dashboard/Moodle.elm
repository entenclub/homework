module Pages.Dashboard.Moodle exposing (Model, Msg, Params, page)

import Api exposing (errorToString)
import Api.Moodle.Moodle exposing (authenticateUser, getSiteName)
import Components.Sidebar
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events
import Element.Font as Font
import Element.Input as Input
import Element.Region as Region
import Http
import I18Next exposing (Translations)
import Models exposing (Course, User)
import Shared
import Spa.Document exposing (Document)
import Spa.Page as Page exposing (Page)
import Spa.Url exposing (Url)
import String
import Styling.Colors exposing (blueColor, darkGreyColor, greenColor, lighterGreyColor, redColor)
import Utils.Darken exposing (darken)


type alias Params =
    ()


type alias Model =
    { url : Url Params
    , device : Shared.Device
    , user : Maybe User
    , courseData : Api.Data (List Course)

    --credentials form
    , moodleUrlInput : String
    , moodleSiteName : Api.Data String
    , moodleUsernameInput : String
    , moodlePasswordInput : String
    , authenticationData : Api.Data User
    , translations : Translations
    }


type Msg
    = ChangeMoodleUrlInput String
    | GotSiteData (Api.Data String)
    | ChangeMoodleUsernameInput String
    | ChangeMoodlePasswordInput String
    | Authenticate
    | GotAuthenticationData (Api.Data User)


page : Page Params Model Msg
page =
    Page.application
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        , load = load
        , save = save
        }


init : Shared.Model -> Url Params -> ( Model, Cmd Msg )
init shared url =
    ( { url = url
      , device = shared.device
      , user = shared.user
      , courseData = Api.NotAsked

      --credentials form
      , moodleUrlInput = ""
      , moodleSiteName = Api.NotAsked
      , moodleUsernameInput = ""
      , moodlePasswordInput = ""
      , authenticationData = Api.NotAsked
      , translations = shared.translations
      }
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ChangeMoodleUrlInput text ->
            ( { model | moodleUrlInput = text }, getSiteName text { onResponse = GotSiteData } )

        GotSiteData data ->
            ( { model | moodleSiteName = data }, Cmd.none )

        ChangeMoodleUsernameInput text ->
            ( { model | moodleUsernameInput = text }, Cmd.none )

        ChangeMoodlePasswordInput text ->
            ( { model | moodlePasswordInput = text }, Cmd.none )

        Authenticate ->
            ( model, authenticateUser model.moodleUrlInput model.moodleUsernameInput model.moodlePasswordInput { onResponse = GotAuthenticationData } )

        GotAuthenticationData data ->
            let
                sitename =
                    case data of
                        Api.Failure e ->
                            case e of
                                Api.BadStatus status _ ->
                                    if status == 401 then
                                        model.moodleSiteName

                                    else
                                        Api.NotAsked

                                _ ->
                                    Api.NotAsked

                        _ ->
                            model.moodleSiteName
            in
            ( { model | authenticationData = data, moodlePasswordInput = "", moodleUsernameInput = "", moodleSiteName = sitename }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


load : Shared.Model -> Model -> ( Model, Cmd msg )
load shared model =
    ( { model | device = shared.device, user = shared.user }, Cmd.none )


save : Model -> Shared.Model -> Shared.Model
save model shared =
    case model.authenticationData of
        Api.Success user ->
            { shared | user = Just user }

        _ ->
            shared


borderRadius : Int
borderRadius =
    20


inputColor : Color
inputColor =
    darken lighterGreyColor -0.05


inputTextColor : Color
inputTextColor =
    rgb 1 1 1


inputStyle : List (Attribute Msg)
inputStyle =
    [ Background.color inputColor
    , Border.width 0
    , Border.rounded 10
    , Font.color inputTextColor
    , alignTop
    , height (px 50)
    ]


view : Model -> Document Msg
view model =
    { title = "dashboard/moodle"
    , body =
        [ el
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
            ((case model.device.class of
                Shared.Desktop ->
                    wrappedRow

                _ ->
                    column
             )
                [ spacing 30, height fill, width fill ]
                [ --sidebar
                  Components.Sidebar.viewSidebar
                    { user = model.user
                    , device = model.device
                    , active = Just "moodle integration"
                    , translations = model.translations
                    }
                , --content
                  column
                    [ width
                        (case model.device.class of
                            Shared.Phone ->
                                fill

                            _ ->
                                fillPortion 4
                        )
                    , height fill
                    , spacing 20
                    ]
                    [ column []
                        [ el [ Font.size 40, Font.bold, alignTop ] (text "moodle integration")
                        , el [] (text "here are some things that have to do with the online learning platform moodle and ways to integrate them into your experience")
                        ]
                    , row [ width fill, height fill ] [ viewCredentialsForm model, el [ width (fillPortion 1) ] none ]
                    ]
                ]
            )
        ]
    }


viewCredentialsForm : Model -> Element Msg
viewCredentialsForm model =
    column
        [ Border.rounded borderRadius
        , Background.color lighterGreyColor
        , width (fillPortion 1)
        , height (fillPortion 1)
        , padding 20
        , spacing 20
        ]
        [ column []
            [ el [ Font.size 30, Font.bold ] (text "enter credentials")
            , el [] (text "make your moodle account accessible to our service")
            ]
        , case model.moodleSiteName of
            Api.Success name ->
                el
                    [ centerX
                    , Font.bold
                    , paddingXY 0 10
                    , Font.size 30
                    , Events.onClick (GotSiteData Api.NotAsked)
                    , pointer
                    ]
                    (text name)

            Api.Loading ->
                el [] (text "Loading...")

            _ ->
                text ""
        , column [ width fill, spacing 10 ]
            (case model.moodleSiteName of
                Api.Success _ ->
                    [ viewStatusIndicatorThingy model.authenticationData
                    , Input.text inputStyle
                        { label = Input.labelAbove [] (text "username")
                        , placeholder = Just (Input.placeholder [] (text "username"))
                        , text = model.moodleUsernameInput
                        , onChange = ChangeMoodleUsernameInput
                        }
                    , Input.currentPassword inputStyle
                        { label = Input.labelAbove [] (text "password")
                        , placeholder = Just (Input.placeholder [] (text "password"))
                        , text = model.moodlePasswordInput
                        , onChange = ChangeMoodlePasswordInput
                        , show = False
                        }
                    , Input.button
                        (inputStyle
                            ++ (if String.isEmpty model.moodleUsernameInput || String.isEmpty model.moodlePasswordInput then
                                    [ Background.color inputColor, Region.description "Username and password are required." ]

                                else
                                    [ Background.color blueColor, pointer ]
                               )
                            ++ [ Font.bold
                               , width fill
                               ]
                        )
                        { label = el [ centerX, centerY ] (text "Authenticate")
                        , onPress =
                            if String.isEmpty model.moodleUsernameInput || String.isEmpty model.moodlePasswordInput then
                                Nothing

                            else
                                Just Authenticate
                        }
                    ]

                _ ->
                    [ Input.text inputStyle
                        { label = Input.labelAbove [] (text "moodle url")
                        , placeholder = Just (Input.placeholder [] (text "https://gym-haan.lms.schulon.org"))
                        , text = model.moodleUrlInput
                        , onChange = ChangeMoodleUrlInput
                        }
                    ]
            )
        , paragraph [ alignBottom, Font.color (rgb 0.8 0.8 0.8) ] [ text "We don't keep your username or password. We just use them to get a token from your moodle site. This token is also kept safe of course." ]
        ]


viewStatusIndicatorThingy : Api.Data User -> Element msg
viewStatusIndicatorThingy userData =
    let
        color =
            case userData of
                Api.Failure _ ->
                    redColor

                Api.Success _ ->
                    greenColor

                _ ->
                    lighterGreyColor

        message =
            case userData of
                Api.Failure e ->
                    Api.errorToString e

                Api.Success _ ->
                    "Success 🎉"

                _ ->
                    ""
    in
    column
        [ Background.color color
        , Border.rounded 10
        , padding 10
        , width fill
        ]
        [ el [ Font.size 25, Font.bold ] (text message)
        ]
