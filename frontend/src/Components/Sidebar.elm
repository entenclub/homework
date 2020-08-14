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
import Spa.Generated.Route as Route exposing (Route)
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
            viewUserComponent user

        Nothing ->
            Element.none


viewSidebar : { user : Maybe User, courseData : Api.Data (List Course), device : Shared.Device, back : Maybe (Element msg), active : Maybe String } -> Element msg
viewSidebar model =
    let
        links =
            [ ( "dashboard", Route.Dashboard )
            , ( "courses", Route.Dashboard__Courses )
            ]
    in
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
                , el [ width fill, paddingXY 0 50 ] (viewLinks links model.active)
                , backButton
                ]

            Nothing ->
                [ viewUser model.user model.courseData
                , el [ width fill, paddingXY 0 50 ] (viewLinks links model.active)
                ]
        )


viewUserComponent : User -> Element msg
viewUserComponent user =
    column [ spacing 10 ]
        [ el
            [ Font.size 30
            , Font.semiBold
            , Font.color (rgb 1 1 1)
            , Font.center
            ]
            (if String.length user.username > 12 then
                text ("Hey, " ++ String.slice 0 12 user.username ++ "...")

             else
                text ("Hey, " ++ user.username)
            )
        , el []
            (case user.privilege of
                Models.Admin ->
                    text "Administrator"

                Models.Normal ->
                    none
            )
        ]


viewLinks : List ( String, Route ) -> Maybe String -> Element msg
viewLinks links maybeActive =
    column [ width fill ]
        (case maybeActive of
            Just active ->
                List.map (\link -> viewLink link (Tuple.first link == active)) links

            Nothing ->
                List.map (\link -> viewLink link False) links
        )


viewLink : ( String, Route ) -> Bool -> Element msg
viewLink linkData active =
    el
        [ Font.bold
        , mouseOver
            [ Background.color (darken lighterGreyColor -0.1)
            ]
        , width fill
        , height (px 50)
        , Border.rounded 10
        , padding 10
        ]
        (link [ centerY ]
            { url = Route.toString (Tuple.second linkData)
            , label =
                el
                    (if active then
                        [ Font.color blueColor ]

                     else
                        []
                    )
                    (text (Tuple.first linkData))
            }
        )
