module Pages.Dashboard exposing (Model, Msg, Params, page)

import Api exposing (Data(..))
import Api.Homework.Analytics exposing (getCourseAnalytics)
import Api.Homework.Assignment exposing (createAssignment)
import Api.Homework.Course exposing (MinimalCourse, getActiveCourses, searchCourses)
import Api.Homework.User exposing (getUserFromSession)
import Array
import Components.CourseChart
import Components.Sidebar
import Date
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
import Models exposing (Assignment, Course, User)
import Shared
import Spa.Document exposing (Document)
import Spa.Generated.Route as Route exposing (Route)
import Spa.Page as Page exposing (Page)
import Spa.Url exposing (Url)
import Styling.Colors exposing (..)
import Task
import Time
import Utils.Darken exposing (darken)
import Utils.Route exposing (navigate)
import Utils.Vh exposing (vh, vw)


type alias Params =
    ()


type alias Model =
    { url : Url Params
    , gotUser : Bool
    , user : Maybe User
    , courseData : Api.Data (List Course)
    , courseAnalyticsData : Api.Data (List Api.Homework.Analytics.CourseAnalyticsData)
    , device : Shared.Device

    -- create assignment form
    , createAssignmentData : Api.Data Assignment
    , searchCoursesText : String
    , searchCoursesData : Api.Data (List MinimalCourse)
    , selectedCourse : Maybe Int
    , selectedCourseFromMoodle : Bool
    , titleTfText : String
    , dateTfText : String
    , selectedDate : Maybe Date.Date
    , today : Date.Date
    , selectedDateTime : Time.Posix
    , addDaysDifference : Int
    , errors : List String
    }


type Msg
    = GotCourseData (Api.Data (List Course))
    | GotCourseAnalyticsData (Api.Data (List Api.Homework.Analytics.CourseAnalyticsData))
    | ViewMoreAssignments
      -- create assignment form
    | SearchCourses String
    | GotSearchCoursesData (Api.Data (List MinimalCourse))
    | CAFSelectCourse MinimalCourse
    | CAFChangeTitle String
    | CAFChangeDate String
    | CreateAssignment
    | GotCreateAssignmentData (Api.Data Assignment)
    | ReceiveTime Time.Posix
    | Add1Day


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
    [ getActiveCourses { onResponse = GotCourseData }
    , getCourseAnalytics { onResponse = GotCourseAnalyticsData }
    , Time.now |> Task.perform ReceiveTime
    ]


init : Shared.Model -> Url Params -> ( Model, Cmd Msg )
init shared url =
    ( { url = url
      , user = shared.user
      , gotUser = False
      , courseData = NotAsked
      , courseAnalyticsData = NotAsked
      , searchCoursesData = NotAsked
      , device = shared.device
      , createAssignmentData = NotAsked
      , searchCoursesText = ""
      , selectedCourse = Nothing
      , selectedCourseFromMoodle = False
      , titleTfText = ""
      , dateTfText = ""
      , selectedDate = Nothing
      , today = Date.fromCalendarDate 2019 Time.Jan 1
      , selectedDateTime = Time.millisToPosix 0
      , addDaysDifference = 0
      , errors = []
      }
    , Cmd.batch initCommands
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotCourseData data ->
            case data of
                Failure e ->
                    case e of
                        Http.BadStatus s ->
                            if s == 401 || s == 403 && model.gotUser then
                                ( model, Utils.Route.navigate model.url.key Route.Login )

                            else
                                ( { model | courseData = data }, Cmd.none )

                        _ ->
                            ( { model | courseData = data }, Cmd.none )

                _ ->
                    ( { model | courseData = data }, Cmd.none )

        GotCourseAnalyticsData data ->
            ( { model | courseAnalyticsData = data }, Cmd.none )

        GotSearchCoursesData data ->
            ( { model | searchCoursesData = data }, Cmd.none )

        ViewMoreAssignments ->
            ( model, navigate model.url.key Route.Dashboard__Courses )

        -- create assignment form
        SearchCourses text ->
            let
                errorMsg =
                    "no course selected"
            in
            if String.isEmpty (String.trim text) then
                ( { model
                    | searchCoursesText = text
                    , searchCoursesData = NotAsked
                    , selectedCourse = Nothing
                    , errors =
                        if List.member errorMsg model.errors then
                            model.errors

                        else
                            List.append model.errors [ errorMsg ]
                  }
                , Cmd.none
                )

            else if model.selectedCourse == Nothing then
                ( { model
                    | searchCoursesText = text
                    , selectedCourse = Nothing
                    , errors =
                        if List.member errorMsg model.errors then
                            model.errors

                        else
                            List.append model.errors [ errorMsg ]
                  }
                , searchCourses text { onResponse = GotSearchCoursesData }
                )

            else
                ( { model | searchCoursesText = text, selectedCourse = Nothing, errors = List.filter (\error -> error /= errorMsg) model.errors }, searchCourses text { onResponse = GotSearchCoursesData } )

        CAFSelectCourse course ->
            ( { model
                | searchCoursesText =
                    if course.fromMoodle then
                        course.name

                    else
                        course.teacher ++ ": " ++ course.subject
                , selectedCourseFromMoodle = course.fromMoodle
                , searchCoursesData = NotAsked
                , selectedCourse = Just course.id
                , errors = List.filter (\error -> error /= "no course selected") model.errors
              }
            , Cmd.none
            )

        CAFChangeTitle text ->
            let
                errorMsg =
                    "missing title"
            in
            if String.isEmpty (String.trim text) then
                if List.member errorMsg model.errors then
                    ( { model
                        | titleTfText = text
                      }
                    , Cmd.none
                    )

                else
                    ( { model
                        | titleTfText = text
                        , errors = List.append model.errors [ errorMsg ]
                      }
                    , Cmd.none
                    )

            else
                ( { model
                    | titleTfText = text
                    , errors = List.filter (\error -> error /= errorMsg) model.errors
                  }
                , Cmd.none
                )

        CAFChangeDate text ->
            let
                errorMsg =
                    "invalid date"

                errorMsg2 =
                    "due date is in the past!"

                epochStartOffset =
                    719162
            in
            case dateStringToDate text of
                Just date ->
                    ( { model
                        | dateTfText = text
                        , selectedDate = Just date
                        , selectedDateTime = Time.millisToPosix (floor (toFloat (Date.toRataDie date) - epochStartOffset) * (1000 * 60 * 60 * 24) - (1000 * 60 * 60 * 24))
                        , addDaysDifference = Date.toRataDie date - epochStartOffset - (Date.toRataDie model.today - epochStartOffset)
                        , errors =
                            List.append (List.filter (\error -> error /= errorMsg && error /= errorMsg2) model.errors)
                                (if Date.toRataDie date - epochStartOffset - (Date.toRataDie model.today - epochStartOffset) < 0 then
                                    [ errorMsg2 ]

                                 else
                                    []
                                )
                      }
                    , Cmd.none
                    )

                Nothing ->
                    if List.member errorMsg model.errors then
                        ( { model
                            | dateTfText = text
                            , selectedDate = Nothing
                            , selectedDateTime = Time.millisToPosix (floor (toFloat (Date.toRataDie model.today) - epochStartOffset) * (1000 * 60 * 60 * 24) - (1000 * 60 * 60 * 24))
                            , errors = List.filter (\error -> error /= errorMsg2) model.errors
                            , addDaysDifference = 0
                          }
                        , Cmd.none
                        )

                    else
                        ( { model
                            | dateTfText = text
                            , selectedDate = Nothing
                            , errors = List.append (List.filter (\error -> error /= errorMsg2) model.errors) [ errorMsg ]
                            , selectedDateTime = Time.millisToPosix (floor (toFloat (Date.toRataDie model.today) - epochStartOffset) * (1000 * 60 * 60 * 24) - (1000 * 60 * 60 * 24))
                            , addDaysDifference = 0
                          }
                        , Cmd.none
                        )

        ReceiveTime time ->
            ( { model | today = Date.fromPosix Time.utc time, selectedDateTime = time }, Cmd.none )

        CreateAssignment ->
            case model.selectedCourse of
                Just course ->
                    case model.selectedDate of
                        Just dueDate ->
                            ( { model | dateTfText = "", searchCoursesText = "", searchCoursesData = NotAsked, selectedCourse = Nothing, errors = [] }
                            , createAssignment
                                { courseId = course
                                , title = model.titleTfText
                                , dueDate = dueDate
                                , fromMoodle = model.selectedCourseFromMoodle
                                }
                                { onResponse = GotCreateAssignmentData }
                            )

                        _ ->
                            ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        GotCreateAssignmentData data ->
            ( { model | createAssignmentData = data }, Cmd.batch [ getActiveCourses { onResponse = GotCourseData }, getCourseAnalytics { onResponse = GotCourseAnalyticsData } ] )

        Add1Day ->
            let
                date =
                    Date.fromPosix Time.utc
                        (Time.millisToPosix
                            (floor
                                (toFloat
                                    (Time.posixToMillis
                                        model.selectedDateTime
                                        + (1000 * 60 * 60 * 24)
                                    )
                                )
                            )
                        )

                -- days between the birth of jesus and 1970-01-01
                epochStartOffset =
                    719162
            in
            ( { model
                | selectedDate = Just date
                , selectedDateTime = Time.millisToPosix (floor (toFloat (Date.toRataDie (Date.fromPosix Time.utc model.selectedDateTime)) - epochStartOffset) * (1000 * 60 * 60 * 24))
                , dateTfText = toGermanDateString date
                , addDaysDifference = Date.toRataDie date - epochStartOffset - (Date.toRataDie model.today - epochStartOffset)
                , errors = List.filter (\error -> error /= "invalid date") model.errors
              }
            , Cmd.none
            )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


load : Shared.Model -> Model -> ( Model, Cmd msg )
load shared model =
    ( { model | device = shared.device, user = shared.user, gotUser = True }, Cmd.none )


save : Model -> Shared.Model -> Shared.Model
save _ shared =
    shared


borderRadius : Int
borderRadius =
    20


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
                  Components.Sidebar.viewSidebar { user = model.user, courseData = model.courseData, device = model.device, active = Just "dashboard" }

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
                    , (case model.device.class of
                        Shared.Desktop ->
                            row

                        _ ->
                            column
                      )
                        [ width fill, height shrink, spacing 30 ]
                        [ viewCreateAssignmentForm model
                        , el [ Background.color lighterGreyColor, Border.rounded borderRadius, width fill, height fill ]
                            (case model.courseAnalyticsData of
                                Api.Success courseData ->
                                    el [ centerX, centerY, width fill ] (html (Components.CourseChart.view courseData))

                                Api.Failure e ->
                                    el [ centerX, centerY ] (text (errorToString e))

                                _ ->
                                    el [ centerX, centerY ] (text "Loading...")
                            )
                        ]
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



-- outstanding? assignments
-- dueDateAfteDate : Date.Date -> Date.Date -> Bool


dueDateAfteDate dueDate date =
    let
        epochStartOffset =
            719162
    in
    Date.toRataDie date - epochStartOffset - (Date.toRataDie dueDate - epochStartOffset) > 0


dateToPosixTime : Date.Date -> Time.Posix
dateToPosixTime date =
    Time.millisToPosix (Date.toRataDie date - 719162 * (1000 * 60 * 60 * 24))


inNDays : Int -> Date.Date -> Date.Date
inNDays days today =
    Date.fromPosix Time.utc
        (Time.millisToPosix
            (floor
                (toFloat
                    (Time.posixToMillis
                        (dateToPosixTime today)
                        + ((1000 * 60 * 60 * 24)
                            * days
                          )
                    )
                )
            )
        )


otherOutstandingAssignments : Date.Date -> List Course -> Int
otherOutstandingAssignments today courses =
    List.length (List.filter (\assignment -> dueDateAfteDate assignment.dueDate (inNDays 3 today)) (List.concat (List.map (\course -> course.assignments) courses)))


viewOustandingAssignments : Model -> Element Msg
viewOustandingAssignments model =
    column
        [ width fill
        , spacing 30
        , Background.color lighterGreyColor
        , padding 30
        , Border.rounded borderRadius
        ]
        [ (case model.device.class of
            Shared.Desktop ->
                row

            _ ->
                column
          )
            [ width fill
            , height (shrink |> minimum 200)
            , spacing 30
            ]
            [ --today
              viewAssignmentsDayColumn model.courseData "today" redColor model.today
            , viewAssignmentsDayColumn model.courseData "tomorrow" yellowColor (Date.add Date.Days 1 model.today)
            , viewAssignmentsDayColumn model.courseData "the day after tomorrow" greenColor (Date.add Date.Days 2 model.today)
            ]
        , case model.courseData of
            Success courses ->
                if otherOutstandingAssignments model.today courses > 0 then
                    el
                        [ width fill
                        , height (px 100)
                        , Border.rounded borderRadius
                        , Background.color lighterGreyColor
                        , mouseOver [ Background.color (darken darkGreyColor -0.1) ]
                        , Events.onClick ViewMoreAssignments
                        , pointer
                        ]
                        (row [ centerX, centerY ]
                            [ el
                                [ Font.bold, Font.size 30 ]
                                (row [ spacing 5 ]
                                    [ el
                                        [ height (px 30)
                                        , Background.color (darken lighterGreyColor -0.2)
                                        , width (px 50)
                                        , Border.rounded 15
                                        , centerY
                                        ]
                                        (el [ centerX, centerY ] (text (String.fromInt (otherOutstandingAssignments model.today courses))))
                                    , text "More"
                                    ]
                                )
                            , el [ centerX, centerY ]
                                (html (Icons.arrow_forward 50 Inherit))
                            ]
                        )

                else
                    none

            _ ->
                none
        ]


filterCoursesByWhetherAssignmentsAreDueOnDate : List Course -> Date.Date -> List Course
filterCoursesByWhetherAssignmentsAreDueOnDate courses date =
    let
        validCourses =
            List.map (\idAssignmentTuple -> Tuple.first idAssignmentTuple)
                (List.filter
                    (\_ ->
                        not
                            (List.isEmpty
                                (List.filter (\assignment -> assignment.dueDate == date)
                                    (List.concat (List.map (\course -> course.assignments) courses))
                                )
                            )
                    )
                    (List.map (\course -> ( course.id, course.assignments )) courses)
                )
    in
    List.filter (\course -> List.member course.id validCourses) courses



--List.filter (\course -> List.member course.id validCourses) courses


viewAssignmentsDayColumn : Api.Data (List Course) -> String -> Color -> Date.Date -> Element msg
viewAssignmentsDayColumn courseData title color date =
    column
        [ Background.color color
        , height (fill |> minimum 200)
        , Border.rounded borderRadius
        , padding 20
        , width (fillPortion 1)
        , spacing 10
        ]
        [ el [ Font.bold ] (text title)
        , case courseData of
            Success allCourses ->
                let
                    courses =
                        filterCoursesByWhetherAssignmentsAreDueOnDate allCourses date
                in
                if List.isEmpty courses then
                    el [ centerX, centerY, Font.size 30, Font.bold ] (text "*nothing 🎉*")

                else
                    Keyed.column [ width fill, spacing 5 ] (List.map (courseGroupToKeyValue color date) courses)

            Failure e ->
                text (errorToString e)

            Loading ->
                el [ centerX, centerY, Font.size 30, Font.bold ] (text "Loading...")

            NotAsked ->
                el [ centerX, centerY, Font.size 30, Font.bold ] (text "Loading...")
        ]


courseGroupToKeyValue : Color -> Date.Date -> Course -> ( String, Element msg )
courseGroupToKeyValue color date course =
    ( String.fromInt course.id, viewAssignmentCourseGroup course color date )


viewAssignmentCourseGroup : Course -> Color -> Date.Date -> Element msg
viewAssignmentCourseGroup course color date =
    let
        assignments =
            List.filter (\assignment -> assignment.dueDate == date) course.assignments
    in
    if not (List.isEmpty assignments) then
        column
            [ Background.color (darken color 0.05)
            , padding 10
            , spacing 10
            , Border.rounded 10
            , width fill
            ]
            [ el [ Font.bold ]
                (paragraph []
                    [ text
                        (if course.fromMoodle then
                            course.name

                         else
                            course.teacher ++ ": " ++ course.subject
                        )
                    ]
                )
            , Keyed.column [ spacing 5, width fill ] (List.map (assignmentToKeyValue color) assignments)
            ]

    else
        none


assignmentToKeyValue : Color -> Assignment -> ( String, Element msg )
assignmentToKeyValue color assignment =
    ( String.fromInt assignment.id, viewAssignment assignment color )


viewAssignment : Assignment -> Color -> Element msg
viewAssignment assignment color =
    column
        [ Background.color (darken color 0.1)
        , padding 10
        , Border.rounded 10
        , width fill
        ]
        [ el [] (paragraph [] [ text assignment.title ]), el [ alignRight, Font.italic ] (text assignment.creator.username) ]



-- create assignment form


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


viewCreateAssignmentFormErrors : List String -> Element Msg
viewCreateAssignmentFormErrors errors =
    if List.isEmpty errors then
        text ""

    else
        column
            [ Background.color redColor
            , width fill
            , Border.rounded 10
            , padding 10
            , spacing 5
            ]
            [ el [ Font.bold, Font.size 30, Font.color (darken redColor 0.8) ] (text "Errors")
            , column []
                (List.map
                    viewCreateAssignmentFormError
                    errors
                )
            ]


viewCreateAssignmentFormError : String -> Element msg
viewCreateAssignmentFormError error =
    el [ Font.bold, Font.color (darken redColor 0.8) ] (text error)


viewCreateAssignmentFormStatus : Api.Data Assignment -> Element msg
viewCreateAssignmentFormStatus data =
    case data of
        Success _ ->
            column
                [ Background.color greenColor
                , width fill
                , Border.rounded 10
                , paddingXY 10 20
                , spacing 5
                ]
                [ el [ Font.bold, Font.size 20, Font.color (darken greenColor 0.8) ] (text "Success 🎉") ]

        Failure _ ->
            column
                [ Background.color redColor
                , width fill
                , Border.rounded 10
                , paddingXY 10 30
                , spacing 5
                ]
                [ el [ Font.bold, Font.size 30, Font.color (darken redColor 0.8) ] (text "Error. Try again?") ]

        _ ->
            none


viewCreateAssignmentForm : Model -> Element Msg
viewCreateAssignmentForm model =
    column
        [ Background.color lighterGreyColor
        , height (fill |> minimum 400)
        , width (fillPortion 1)
        , Border.rounded borderRadius
        , padding 20
        , Font.color darkGreyColor
        , spacing 10
        ]
        [ el [ Font.bold, Font.size 30, Font.color inputTextColor ]
            (text "Create Assignment")
        , viewCreateAssignmentFormErrors model.errors
        , viewCreateAssignmentFormStatus model.createAssignmentData
        , (case model.device.class of
            Shared.Phone ->
                column

            _ ->
                row
          )
            [ width fill, spacing 10 ]
            [ column [ width fill ]
                [ Input.text
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
                    , height (px 50)
                    ]
                    { label = Input.labelAbove [ Font.color (rgb 1 1 1) ] (text "search courses (required)")
                    , placeholder = Just (Input.placeholder [] (text "Emily Oliver: History"))
                    , onChange = SearchCourses
                    , text = model.searchCoursesText
                    }
                , viewSearchDropdown model.searchCoursesData
                ]
            , Input.text
                (List.append
                    inputStyle
                    [ alignTop ]
                )
                { label = Input.labelAbove [ Font.color (rgb 1 1 1) ] (text "title (required)")
                , placeholder = Just (Input.placeholder [] (text "sb. page 105, 1-3a"))
                , onChange = CAFChangeTitle
                , text = model.titleTfText
                }
            ]
        , row
            [ width fill ]
            [ Input.text
                (List.append
                    inputStyle
                    [ Border.roundEach { topLeft = 10, topRight = 0, bottomLeft = 10, bottomRight = 0 } ]
                )
                { label =
                    Input.labelAbove [ Font.color (rgb 1 1 1) ]
                        (text
                            (case model.selectedDate of
                                Just _ ->
                                    "due date (required) -- selected date " ++ String.fromInt model.addDaysDifference ++ " days from now."

                                Nothing ->
                                    "due date (required)"
                            )
                        )
                , placeholder = Just (Input.placeholder [] (text (toGermanDateString model.today)))
                , onChange = CAFChangeDate
                , text = model.dateTfText
                }
            , el
                (List.append inputStyle
                    [ width (px 50)
                    , height (px 50)
                    , alignBottom
                    , Border.roundEach { topLeft = 0, topRight = 10, bottomLeft = 0, bottomRight = 10 }
                    , Border.widthEach { left = 2, right = 0, bottom = 0, top = 0 }
                    , Border.dotted
                    , Border.color inputTextColor
                    , mouseOver
                        [ Background.color (darken inputColor -0.05)
                        ]
                    , Events.onClick Add1Day
                    , pointer
                    ]
                )
                (el [ centerX, centerY, Font.size 30, Font.bold ] (text "+1"))
            ]
        , if not (List.isEmpty model.errors) || (String.isEmpty model.titleTfText || String.isEmpty model.searchCoursesText || String.isEmpty model.dateTfText) then
            Input.button
                [ width fill
                , height (px 50)
                , Background.color (darken inputColor -0.1)
                , Font.color (rgb 1 1 1)
                , Font.bold
                , Border.rounded 10
                , padding 10
                ]
                { label = el [ centerX, centerY ] (text "Submit")
                , onPress = Nothing
                }

          else
            Input.button
                [ width fill
                , height (px 50)
                , Background.color blueColor
                , Font.color (rgb 1 1 1)
                , Font.bold
                , Border.rounded 10
                , padding 10
                ]
                { label = el [ centerX, centerY ] (text "Submit")
                , onPress = Just CreateAssignment
                }
        ]


viewSearchDropdown : Api.Data (List MinimalCourse) -> Element Msg
viewSearchDropdown data =
    case data of
        Success courses ->
            let
                shortedCourses =
                    Array.toList (Array.slice 0 10 (Array.fromList courses))

                maybeLast =
                    List.head (List.reverse shortedCourses)
            in
            case maybeLast of
                Just last ->
                    Keyed.column [ width fill, height fill, scrollbarY ]
                        (List.map
                            (courseToKeyValue last)
                            shortedCourses
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
        , height (shrink |> minimum 50)
        , padding 15
        , if isLast then
            Border.roundEach { topLeft = 0, bottomLeft = 10, bottomRight = 10, topRight = 0 }

          else
            Border.rounded 0
        , mouseOver
            [ Background.color (darken inputColor -0.05)
            ]
        , Events.onClick (CAFSelectCourse course)
        , spacing 10
        ]
        [ if course.fromMoodle then
            el [ Background.color (rgb255 249 128 18), Font.bold, Font.color (rgb 1 1 1), Border.rounded 5, padding 5 ]
                (text "moodle")

          else
            none
        , el
            [ Font.bold, Font.color inputTextColor, width fill ]
            (paragraph [ width fill ]
                [ text
                    (if course.fromMoodle then
                        course.name

                     else
                        course.teacher ++ ": " ++ course.subject
                    )
                ]
            )
        ]


dateStringToDate : String -> Maybe Date.Date
dateStringToDate input =
    let
        data =
            Array.fromList (String.split "." input)
    in
    case Array.get 0 data of
        Just dayStr ->
            case String.toInt dayStr of
                Just day ->
                    case Array.get 1 data of
                        Just monthStr ->
                            case String.toInt monthStr of
                                Just monthInt ->
                                    case Array.get 2 data of
                                        Just yearStr ->
                                            case String.toInt yearStr of
                                                Just year ->
                                                    case monthInt of
                                                        1 ->
                                                            dayMonthYearToDate day Time.Jan year

                                                        2 ->
                                                            dayMonthYearToDate day Time.Feb year

                                                        3 ->
                                                            dayMonthYearToDate day Time.Mar year

                                                        4 ->
                                                            dayMonthYearToDate day Time.Apr year

                                                        5 ->
                                                            dayMonthYearToDate day Time.May year

                                                        6 ->
                                                            dayMonthYearToDate day Time.Jun year

                                                        7 ->
                                                            dayMonthYearToDate day Time.Jul year

                                                        8 ->
                                                            dayMonthYearToDate day Time.Aug year

                                                        9 ->
                                                            dayMonthYearToDate day Time.Sep year

                                                        10 ->
                                                            dayMonthYearToDate day Time.Oct year

                                                        11 ->
                                                            dayMonthYearToDate day Time.Nov year

                                                        12 ->
                                                            dayMonthYearToDate day Time.Dec year

                                                        _ ->
                                                            Nothing

                                                Nothing ->
                                                    Nothing

                                        Nothing ->
                                            Nothing

                                Nothing ->
                                    Nothing

                        Nothing ->
                            Nothing

                Nothing ->
                    Nothing

        Nothing ->
            Nothing


dayMonthYearToDate : Int -> Time.Month -> Int -> Maybe Date.Date
dayMonthYearToDate day month year =
    Just (Date.fromCalendarDate year month day)


toGermanDateString : Date.Date -> String
toGermanDateString date =
    Date.format "d.M.y" date
