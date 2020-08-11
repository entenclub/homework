module Pages.Dashboard exposing (Model, Msg, Params, page)

import Api exposing (Data(..))
import Api.Homework.User exposing (getUserFromSession)
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Element.Keyed as Keyed
import Http exposing (riskyRequest)
import Shared exposing (Assignment, Course, User)
import Spa.Document exposing (Document)
import Spa.Page as Page exposing (Page)
import Spa.Url exposing (Url)
import Time
import Utils.Darken exposing (darken)
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
                    ]
                    [ viewOustandingAssignments model ]
                ]
            )
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



-- outstanding? assignments


mockupAssignments : List Assignment
mockupAssignments =
    [ { id = 1, creator = { id = 14, username = "enteee", privilege = 1, email = "gott@3nt3.de" }, title = "test assignment #1", description = Nothing, course = 0, dueDate = Time.millisToPosix 1597127700077 } ]


mockupCourses : List Course
mockupCourses =
    [ { id = 1, teacher = "Robin Ejaz", assignments = mockupAssignments, subject = "Geschichte" } ]


viewOustandingAssignments : Model -> Element msg
viewOustandingAssignments model =
    row
        [ width fill
        , height (px 400)
        , spacing 30
        ]
        [ --today
          viewAssignmentsDayColumn mockupCourses "today" redColor
        , viewAssignmentsDayColumn mockupCourses "tomorrow" yellowColor
        , viewAssignmentsDayColumn mockupCourses "the day after tomorrow" greenColor
        ]


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
