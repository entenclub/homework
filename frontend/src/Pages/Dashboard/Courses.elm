module Pages.Dashboard.Courses exposing (Model, Msg, Params, page)

import Api
import Api.Homework.Course exposing (getActiveCourses)
import Components.Sidebar
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events
import Element.Font as Font
import Material.Icons as Icons
import Material.Icons.Types exposing (Coloring(..))
import Models exposing (Course, User)
import Shared exposing (subscriptions)
import Spa.Document exposing (Document)
import Spa.Generated.Route as Route exposing (Route)
import Spa.Page as Page exposing (Page)
import Spa.Url exposing (Url)
import Utils.Darken exposing (darken)
import Utils.Route


type alias Model =
    { url : Url Params
    , device : Shared.Device
    , user : Maybe User
    , courseData : Api.Data (List Course)
    }


type Msg
    = GotCourseData (Api.Data (List Course))


type alias Params =
    ()


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


initCommands : List (Cmd Msg)
initCommands =
    [ getActiveCourses { onResponse = GotCourseData } ]


init : Shared.Model -> Url Params -> ( Model, Cmd Msg )
init shared url =
    ( { url = url
      , device = shared.device
      , user = shared.user
      , courseData = Api.NotAsked
      }
    , Cmd.batch initCommands
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotCourseData data ->
            ( { model | courseData = data }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


load : Shared.Model -> Model -> ( Model, Cmd msg )
load shared model =
    ( { model | device = shared.device }, Cmd.none )


save : Model -> Shared.Model -> Shared.Model
save _ shared =
    shared



-- styling


borderRadius : Int
borderRadius =
    20


blueColor : Color
blueColor =
    rgb255 45 156 252


redColor : Color
redColor =
    rgb255 255 82 96


greenColor : Color
greenColor =
    rgb255 80 214 68


yellowColor : Color
yellowColor =
    rgb255 220 200 69


lighterGreyColor : Color
lighterGreyColor =
    rgb255 29 32 37


darkGreyColor : Color
darkGreyColor =
    rgb255 26 28 33


inputColor : Color
inputColor =
    darken lighterGreyColor -0.05


inputTextColor : Color
inputTextColor =
    rgb 0.8 0.8 0.8


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
    { title = "courses"
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
                [ spacing 30
                , height fill
                , width fill
                ]
                [ -- sidebar
                  Components.Sidebar.viewSidebar
                    { user = model.user
                    , courseData = model.courseData
                    , device = model.device
                    , back = Just backButton
                    }

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
                    , spacing 30
                    ]
                    []
                ]
            )
        ]
    }


backButton : Element msg
backButton =
    el
        [ alignBottom
        , width fill
        , Background.color (darken lighterGreyColor -0.1)
        , Border.rounded 10
        , height (px 70)
        , mouseOver
            [ Background.color (darken lighterGreyColor -0.2)
            ]
        ]
        (link
            [ Font.bold
            , Font.size 30
            , centerX
            , centerY
            ]
            { label =
                row [ spacing 10 ]
                    [ el [ centerY ] (html (Icons.arrow_back 40 Inherit))
                    , text
                        "Back"
                    ]
            , url = Route.toString Route.Dashboard
            }
        )
