module Pages.Dashboard.Moodle exposing (Model, Msg, Params, page)

import Api
import Api.Moodle.Moodle exposing (getSiteName)
import Components.Sidebar
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Models exposing (Course, User)
import Shared
import Spa.Document exposing (Document)
import Spa.Generated.Route as Route exposing (Route)
import Spa.Page as Page exposing (Page)
import Spa.Url exposing (Url)
import Styling.Colors exposing (darkGreyColor, lighterGreyColor)
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
    }


type Msg
    = ChangeMoodleUrlInput String
    | GotSiteData (Api.Data String)


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


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


load : Shared.Model -> Model -> ( Model, Cmd msg )
load shared model =
    ( { model | device = shared.device, user = shared.user }, Cmd.none )


save : Model -> Shared.Model -> Shared.Model
save _ shared =
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
                    , courseData = model.courseData
                    , device = model.device
                    , active = Just "moodle integration"
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
                    ]
                    (text name)

            Api.Loading ->
                el [] (text "Loading...")

            _ ->
                text ""
        , column [ width fill ]
            [ Input.text inputStyle
                { label = Input.labelAbove [] (text "moodle url")
                , placeholder = Just (Input.placeholder [] (text "https://gym-haan.lms.schulon.org"))
                , text = model.moodleUrlInput
                , onChange = ChangeMoodleUrlInput
                }
            ]
        ]
