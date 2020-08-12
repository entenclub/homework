module Pages.Dashboard exposing (Model, Msg, Params, page)

import Api exposing (Data(..))
import Api.Homework.Course exposing (MinimalCourse, getActiveCourses, searchCourses)
import Api.Homework.User exposing (getUserFromSession)
import Array
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events
import Element.Font as Font
import Element.Input as Input
import Element.Keyed as Keyed
import Html.Events exposing (onFocus)
import Http exposing (riskyRequest)
import Json.Decode exposing (errorToString)
import Material.Icons as Icons
import Material.Icons.Types exposing (Coloring(..))
import Shared exposing (Assignment, Course, User)
import Spa.Document exposing (Document)
import Spa.Generated.Route as Route exposing (Route)
import Spa.Page as Page exposing (Page)
import Spa.Url exposing (Url)
import Time
import Utils.Darken exposing (darken)
import Utils.Route exposing (navigate)
import Utils.Vh exposing (vh, vw)


type alias Params =
    ()


type alias Model =
    { url : Url Params
    , userData : Api.Data User
    , courseData : Api.Data (List Course)
    , device : Shared.Device

    -- create assignment form
    , searchCoursesText : String
    , searchCoursesData : Api.Data (List MinimalCourse)
    , selectedCourse : Maybe Int
    }


type Msg
    = GotUserData (Api.Data User)
    | GotCourseData (Api.Data (List Course))
    | ViewMoreAssignments
      -- create assignment form
    | SearchCourses String
    | GotSearchCoursesData (Api.Data (List MinimalCourse))
    | CAFSelectCourse MinimalCourse
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


initCommands : List (Cmd Msg)
initCommands =
    [ getUserFromSession { onResponse = GotUserData }
    , getActiveCourses { onResponse = GotCourseData }
    ]


init : Shared.Model -> Url Params -> ( Model, Cmd Msg )
init shared url =
    ( { url = url, userData = NotAsked, courseData = NotAsked, searchCoursesData = NotAsked, device = shared.device, searchCoursesText = "", selectedCourse = Nothing }, Cmd.batch initCommands )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotUserData data ->
            ( { model | userData = data }, Cmd.none )

        GotCourseData data ->
            ( { model | courseData = data }, Cmd.none )

        GotSearchCoursesData data ->
            ( { model | searchCoursesData = data }, Cmd.none )

        Refresh ->
            ( model, getUserFromSession { onResponse = GotUserData } )

        ViewMoreAssignments ->
            ( model, navigate model.url.key Route.Dashboard__Courses )

        -- create assignment form
        SearchCourses text ->
            if text == "" then
                ( { model | searchCoursesText = text, searchCoursesData = NotAsked, selectedCourse = Nothing }, Cmd.none )

            else
                ( { model | searchCoursesText = text, selectedCourse = Nothing }, searchCourses text { onResponse = GotSearchCoursesData } )

        CAFSelectCourse course ->
            ( { model | searchCoursesText = course.teacher ++ ": " ++ course.subject, searchCoursesData = NotAsked, selectedCourse = Just course.id }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


load : Shared.Model -> Model -> ( Model, Cmd msg )
load shared model =
    ( { model | device = shared.device }, Cmd.none )


save : Model -> Shared.Model -> Shared.Model
save _ shared =
    shared


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


view : Model -> Document Msg
view model =
    { title = "dashboard"
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
                    , spacing 30
                    ]
                    [ viewOustandingAssignments model
                    , row [ width fill, height fill ] [ viewCreateAssignmentForm model, el [ width (fillPortion 1) ] none ]
                    ]
                ]
            )
        ]
    }


errorToString : Http.Error -> String
errorToString error =
    case error of
        Http.BadStatus status ->
            "bad status: " ++ String.fromInt status

        Http.BadBody err ->
            "bad body: " ++ err

        Http.BadUrl err ->
            "bad url: " ++ err

        Http.NetworkError ->
            "network error"

        Http.Timeout ->
            "timeout"


viewUser : Api.Data User -> Element msg
viewUser data =
    case data of
        Success user ->
            viewUserComponent user

        Loading ->
            text "Loading..."

        Failure error ->
            text (errorToString error)

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
            (case user.privilege of
                Shared.Admin ->
                    text "Administrator"

                Shared.Normal ->
                    none
            )
        ]



-- outstanding? assignments


viewOustandingAssignments : Model -> Element Msg
viewOustandingAssignments model =
    case model.courseData of
        Success courses ->
            column
                [ width fill
                , spacing 30
                , Background.color lighterGreyColor
                , padding 30
                , Border.rounded borderRadius
                ]
                [ row
                    [ width fill
                    , height (px 400)
                    , spacing 30
                    ]
                    [ --today
                      viewAssignmentsDayColumn courses "today" redColor
                    , viewAssignmentsDayColumn courses "tomorrow" yellowColor
                    , viewAssignmentsDayColumn courses "the day after tomorrow" greenColor
                    ]
                , el
                    [ width fill
                    , height (px 100)
                    , Border.rounded borderRadius
                    , Background.color lighterGreyColor
                    , mouseOver [ Background.color (darken darkGreyColor -0.1) ]
                    , Events.onClick ViewMoreAssignments
                    ]
                    (row [ centerX, centerY ]
                        [ el [ centerX, centerY ]
                            (html (Icons.arrow_forward 50 Inherit))
                        , el
                            [ Font.bold, Font.size 30 ]
                            (text "More")
                        ]
                    )
                ]

        Loading ->
            column [ centerX, centerY, width fill, height fill ]
                [ text "Loading..."
                ]

        Failure e ->
            column [ centerX, centerY, width fill, height fill ]
                [ text "Error!"
                , text (errorToString e)
                ]

        NotAsked ->
            none


viewAssignmentsDayColumn : List Course -> String -> Color -> Element msg
viewAssignmentsDayColumn courses title color =
    column
        [ Background.color color
        , height fill
        , Border.rounded borderRadius
        , padding 20
        , width (fillPortion 1)
        , spacing 10
        ]
        [ el [ Font.bold ] (text title)
        , Keyed.column [ width fill ] (List.map (courseGroupToKeyValue color) courses)
        ]


courseGroupToKeyValue : Color -> Course -> ( String, Element msg )
courseGroupToKeyValue color course =
    ( String.fromInt course.id, viewAssignmentCourseGroup course color )


viewAssignmentCourseGroup : Course -> Color -> Element msg
viewAssignmentCourseGroup course color =
    column
        [ Background.color (darken color 0.05)
        , padding 10
        , spacing 10
        , Border.rounded 10
        , width fill
        ]
        [ el [ Font.bold ] (text (course.teacher ++ " - " ++ course.subject))
        , Keyed.column [] (List.map (assignmentToKeyValue color) course.assignments)
        ]


assignmentToKeyValue : Color -> Assignment -> ( String, Element msg )
assignmentToKeyValue color assignment =
    ( String.fromInt assignment.id, viewAssignment assignment color )


viewAssignment : Assignment -> Color -> Element msg
viewAssignment assignment color =
    column
        [ Background.color (darken color 0.1)
        , padding 10
        , Border.rounded 10
        ]
        [ el [] (text assignment.title) ]



-- create assignment form


inputColor : Color
inputColor =
    darken lighterGreyColor -0.05


inputTextColor =
    rgb 0.8 0.8 0.8


viewCreateAssignmentForm : Model -> Element Msg
viewCreateAssignmentForm model =
    column
        [ Background.color lighterGreyColor
        , height (fill |> minimum 400)
        , width (fillPortion 1)
        , Border.rounded borderRadius
        , padding 20
        , Font.color darkGreyColor
        ]
        [ el [ Font.bold, Font.size 30, Font.color inputTextColor ]
            (text "Create Assignment")
        , Input.text
            [ Background.color inputColor
            , Border.width 0
            , if model.searchCoursesData == NotAsked then
                Border.rounded 10

              else
                Border.roundEach
                    { topLeft = 10
                    , topRight = 10
                    , bottomLeft = 0
                    , bottomRight = 0
                    }
            , Font.color (rgb 1 1 1)
            ]
            { label = Input.labelAbove [ Font.color (rgb 1 1 1) ] (text "search courses")
            , placeholder = Nothing
            , onChange = SearchCourses
            , text = model.searchCoursesText
            }
        , viewSearchDropdown model.searchCoursesData
        ]


viewSearchDropdown : Api.Data (List MinimalCourse) -> Element Msg
viewSearchDropdown data =
    case data of
        Success courses ->
            let
                shortedCourses =
                    Array.toList (Array.slice 0 5 (Array.fromList courses))

                maybeLast =
                    List.head (List.reverse shortedCourses)
            in
            case maybeLast of
                Just last ->
                    Keyed.column [ width fill, height fill, scrollbarY ]
                        (List.map
                            (courseToKeyValue last)
                            (Array.toList
                                (Array.slice 0 5 (Array.fromList courses))
                            )
                        )

                Nothing ->
                    none

        Loading ->
            text "Loading..."

        Failure e ->
            text (errorToString e)

        _ ->
            none


courseToKeyValue : MinimalCourse -> MinimalCourse -> ( String, Element Msg )
courseToKeyValue last course =
    ( String.fromInt course.id, viewSearchDropdownElement course (course.id == last.id) )


viewSearchDropdownElement : MinimalCourse -> Bool -> Element Msg
viewSearchDropdownElement course isLast =
    row
        [ Background.color inputColor
        , width fill
        , height (px 50)
        , padding 15
        , if isLast then
            Border.roundEach { topLeft = 0, bottomLeft = 10, bottomRight = 10, topRight = 0 }

          else
            Border.rounded 0
        , mouseOver
            [ Background.color (darken inputColor -0.05)
            ]
        , Events.onClick (CAFSelectCourse course)
        ]
        [ el [ Font.bold, Font.color (rgb 0.8 0.8 0.8) ] (text (course.teacher ++ ": " ++ course.subject))
        ]
