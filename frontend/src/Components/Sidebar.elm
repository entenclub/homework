module Components.Sidebar exposing (viewSidebar)

import Api exposing (Data(..))
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events
import Element.Font as Font
import Http
import Material.Icons as Icons
import Material.Icons.Types exposing (Coloring(..))
import Models exposing (Course, User)
import Shared
import Spa.Generated.Route exposing (Route)
import Styling.Colors exposing (..)
import Utils.Darken exposing (darken)


borderRadius : Int
borderRadius =
    20


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


viewUser : Maybe User -> Api.Data (List Course) -> Element msg
viewUser maybeUser courseData =
    case maybeUser of
        Just user ->
            case courseData of
                Success courses ->
                    viewUserComponent user courses

                Loading ->
                    text "Loading..."

                Failure error ->
                    text (errorToString error)

                NotAsked ->
                    Element.none

        Nothing ->
            Element.none


viewSidebar : { user : Maybe User, courseData : Api.Data (List Course), device : Shared.Device, back : Maybe (Element msg) } -> Element msg
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
        (case model.back of
            Just backButton ->
                [ viewUser model.user model.courseData
                , backButton
                ]

            Nothing ->
                [ viewUser model.user model.courseData ]
        )


viewUserComponent : User -> List Course -> Element msg
viewUserComponent user courses =
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
                Models.Admin ->
                    text "Administrator"

                Models.Normal ->
                    none
            )
        , el
            [ centerX
            , padding 10
            ]
            (column [] [ el [] (text ("You are enrolled in " ++ String.fromInt (List.length courses) ++ " courses.")) ])
        ]
