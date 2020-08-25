module Pages.Dashboard.Courses exposing (Model, Msg, Params, page)

import Api
import Api.Homework.Course exposing (createCourse, enrollInCourse, getActiveCourses)
import Array
import Components.Sidebar
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events
import Element.Font as Font
import Element.Input as Input
import Http
import List
import Material.Icons as Icons
import Material.Icons.Types exposing (Coloring(..))
import Models exposing (Course, User)
import Shared exposing (subscriptions)
import Spa.Document exposing (Document)
import Spa.Generated.Route as Route exposing (Route)
import Spa.Page as Page exposing (Page)
import Spa.Url exposing (Url)
import Styling.Colors exposing (..)
import Utils.Darken exposing (darken)
import Utils.Route


type alias Model =
    { url : Url Params
    , device : Shared.Device
    , user : Maybe User
    , courseData : Api.Data (List Course)
    , teacherText : String
    , subjectText : String
    , createCourseErrors : List String
    , inviteCodeText : String
    }


type Msg
    = GotCourseData (Api.Data (List Course))
    | ChangeTeacherText String
    | ChangeSubjectText String
    | CreateCourse
    | GotCreateCourseResponse (Api.Data Course)
    | ChangeInviteCodeText String
    | EnrollInCourse
    | GotEnrollData (Api.Data User)


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
      , teacherText = ""
      , subjectText = ""
      , createCourseErrors = [ "please set a teacher", "please set a subject" ]
      , inviteCodeText = ""
      }
    , Cmd.batch initCommands
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotCourseData data ->
            ( { model | courseData = data }, Cmd.none )

        ChangeTeacherText text ->
            let
                errorMsg =
                    "please set a teacher"
            in
            if String.isEmpty (String.trim text) then
                if List.member errorMsg model.createCourseErrors then
                    ( { model
                        | teacherText = text
                      }
                    , Cmd.none
                    )

                else
                    ( { model | teacherText = text, createCourseErrors = model.createCourseErrors ++ [ errorMsg ] }, Cmd.none )

            else
                ( { model | teacherText = text, createCourseErrors = List.filter (\error -> error /= errorMsg) model.createCourseErrors }, Cmd.none )

        ChangeSubjectText text ->
            let
                errorMsg =
                    "please set a subject"
            in
            if String.isEmpty (String.trim text) then
                if List.member errorMsg model.createCourseErrors then
                    ( { model
                        | subjectText = text
                      }
                    , Cmd.none
                    )

                else
                    ( { model | subjectText = text, createCourseErrors = model.createCourseErrors ++ [ errorMsg ] }, Cmd.none )

            else
                ( { model | subjectText = text, createCourseErrors = List.filter (\error -> error /= errorMsg) model.createCourseErrors }, Cmd.none )

        CreateCourse ->
            ( model, createCourse model.subjectText model.teacherText { onResponse = GotCreateCourseResponse } )

        GotCreateCourseResponse data ->
            case data of
                Api.Success course ->
                    case model.courseData of
                        Api.Success courses ->
                            ( { model | courseData = Api.Success (courses ++ [ course ]) }, Cmd.none )

                        _ ->
                            ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        ChangeInviteCodeText text ->
            ( { model | inviteCodeText = text }, Cmd.none )

        EnrollInCourse ->
            case List.head (List.reverse (String.split "#" model.inviteCodeText)) of
                Just idString ->
                    case String.toInt idString of
                        Just id ->
                            ( model, enrollInCourse id { onResponse = GotEnrollData } )

                        Nothing ->
                            ( model, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        GotEnrollData data ->
            case data of
                Api.Success user ->
                    ( { model | user = Just user }, getActiveCourses { onResponse = GotCourseData } )

                _ ->
                    ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


load : Shared.Model -> Model -> ( Model, Cmd msg )
load shared model =
    ( { model | device = shared.device, user = shared.user }, Cmd.none )


save : Model -> Shared.Model -> Shared.Model
save model shared =
    if model.user /= Nothing then
        { shared | user = model.user }

    else
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


view : Model -> Document Msg
view model =
    { title = "dashboard/courses"
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
                    , active = Just "courses"
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
                    [ row [ width fill, spacing 30 ]
                        [ viewCreateCourse model
                        , viewEnrollInCourse model
                        ]
                    , viewMyCourses model.courseData
                    ]
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


viewMyCourses : Api.Data (List Course) -> Element Msg
viewMyCourses courseData =
    column
        [ Background.color lighterGreyColor
        , Border.rounded borderRadius
        , width fill
        , height fill
        , padding 20
        , spacing 10
        ]
        [ el
            [ Font.bold
            , Font.size 30
            ]
            (text "Your courses")
        , case courseData of
            Api.Success courses ->
                if not (List.isEmpty courses) then
                    column [ width fill ] (List.map (\course -> viewCourseRow course) courses)

                else
                    el [ centerX, centerY ] (text "You are not enrolled in any courses.")

            Api.Loading ->
                text "Loading..."

            Api.Failure e ->
                text (errorToString e)

            Api.NotAsked ->
                none
        ]


generateInviteCode : Course -> String
generateInviteCode course =
    let
        maybeLastname =
            List.head (List.reverse (String.split " " course.teacher))
    in
    case maybeLastname of
        Just lastName ->
            String.slice 0 3 lastName ++ String.slice 0 3 course.subject ++ "#" ++ String.fromInt course.id

        Nothing ->
            String.slice 0 3 course.subject ++ "#" ++ String.fromInt course.id


viewCourseRow : Course -> Element msg
viewCourseRow course =
    row
        [ height (shrink |> minimum 50)
        , width fill
        , spacing 50
        , Border.widthEach { top = 0, right = 0, left = 0, bottom = 2 }
        , Border.color inputTextColor
        ]
        [ text (course.teacher ++ ": " ++ course.subject)
        , el
            [ alignRight ]
            (text
                (generateInviteCode course)
            )
        ]


viewCreateCourseFormErrors : List String -> Element Msg
viewCreateCourseFormErrors errors =
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
                    viewCreateCourseFormError
                    errors
                )
            ]


viewCreateCourseFormError : String -> Element msg
viewCreateCourseFormError error =
    el [ Font.bold, Font.color (darken redColor 0.8) ] (text error)


viewCreateCourse : Model -> Element Msg
viewCreateCourse model =
    column
        [ Background.color lighterGreyColor
        , height (fill |> minimum 400)
        , width (fillPortion 1)
        , Border.rounded borderRadius
        , padding 20
        , spacing 10
        ]
        [ el [ Font.size 30, Font.bold ]
            (text "Create Course")
        , viewCreateCourseFormErrors model.createCourseErrors
        , column [ width fill, spacing 10 ]
            [ row
                [ spacing 10, width fill ]
                [ Input.text (inputStyle ++ [ width fill ])
                    { label = Input.labelAbove [] (text "teacher (required)")
                    , text = model.teacherText
                    , onChange = ChangeTeacherText
                    , placeholder = Nothing
                    }
                , Input.text (inputStyle ++ [ width fill ])
                    { label = Input.labelAbove [] (text "subject (required)")
                    , text = model.subjectText
                    , onChange = ChangeSubjectText
                    , placeholder = Nothing
                    }
                ]
            , let
                active =
                    List.isEmpty model.createCourseErrors

                bgColor =
                    if active then
                        blueColor

                    else
                        darken lighterGreyColor -0.1
              in
              Input.button
                (inputStyle
                    ++ [ width fill
                       , height (px 50)
                       , Background.color bgColor
                       , Font.bold
                       ]
                    ++ (if active then
                            [ mouseOver [ Background.color (darken bgColor -0.1) ], pointer ]

                        else
                            []
                       )
                )
                { label = el [ centerX, centerY ] (text "create course")
                , onPress =
                    if List.isEmpty model.createCourseErrors then
                        Just CreateCourse

                    else
                        Nothing
                }
            ]
        ]


viewEnrollInCourse : Model -> Element Msg
viewEnrollInCourse model =
    column
        [ Background.color lighterGreyColor
        , Border.rounded 20
        , height (fill |> minimum 400)
        , width (fillPortion 1)
        , padding 20
        , spacing 10
        ]
        [ el [ Font.size 30, Font.bold ] (text "Enroll in course")
        , Input.text inputStyle
            { label = Input.labelAbove [] (text "invite code")
            , onChange = ChangeInviteCodeText
            , text = model.inviteCodeText
            , placeholder = Nothing
            }
        , let
            active =
                not (String.isEmpty (String.trim model.inviteCodeText))

            bgColor =
                if active then
                    blueColor

                else
                    darken lighterGreyColor -0.1
          in
          Input.button
            (inputStyle
                ++ [ width fill
                   , height (px 50)
                   , Background.color bgColor
                   , alignTop
                   , Font.bold
                   ]
                ++ (if active then
                        [ mouseOver [ Background.color (darken bgColor -0.1) ], pointer ]

                    else
                        []
                   )
            )
            { label = el [ centerX, centerY ] (text "enroll")
            , onPress =
                if active then
                    Just EnrollInCourse

                else
                    Nothing
            }
        ]
