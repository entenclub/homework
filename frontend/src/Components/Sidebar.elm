module Components.Sidebar exposing (viewSidebar)

import Api exposing (Data(..))
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import I18Next exposing (Translations)
import Material.Icons.Types exposing (Coloring(..))
import Models exposing (Course, Privilege, User)
import Shared
import Spa.Generated.Route as Route exposing (Route)
import Styling.Colors exposing (..)
import Translations.Global
import Translations.Pages.Dashboard
import Utils.Darken exposing (darken)


type alias Link =
    { id : String
    , name : String
    , route : Route
    }


borderRadius : Int
borderRadius =
    20


viewUser : Maybe User -> Translations -> Element msg
viewUser maybeUser translations =
    case maybeUser of
        Just user ->
            viewUserComponent user translations

        Nothing ->
            Element.none


viewSidebar : { user : Maybe User, device : Shared.Device, active : Maybe String, translations : Translations } -> Element msg
viewSidebar model =
    let
        links =
            [ Link "dashboard" (Translations.Global.dashboard model.translations) Route.Dashboard
            , Link "moodle integration" (Translations.Pages.Dashboard.moodleIntegration model.translations) Route.Dashboard__Moodle
            ]
                ++ (case model.user of
                        Just user ->
                            case user.privilege of
                                Models.Admin ->
                                    [ Link "admin" (Translations.Pages.Dashboard.admin model.translations) Route.Dashboard__Admin ]

                                _ ->
                                    []

                        Nothing ->
                            []
                   )
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
        [ viewUser model.user model.translations
        , el [ width fill, paddingXY 0 50 ] (viewLinks links model.active)
        ]


viewUserComponent : User -> Translations -> Element msg
viewUserComponent user translations =
    column [ spacing 10 ]
        [ el
            [ Font.size 30
            , Font.semiBold
            , Font.color (rgb 1 1 1)
            , Font.center
            ]
            (text
                (Translations.Global.heyUsername translations
                    (String.slice 0 12 user.username
                        ++ (if String.length user.username > 12 then
                                "..."

                            else
                                ""
                           )
                    )
                )
            )
        , el []
            (case user.privilege of
                Models.Admin ->
                    text "Administrator"

                Models.Normal ->
                    none
            )
        ]


viewLinks : List Link -> Maybe String -> Element msg
viewLinks links maybeActive =
    column [ width fill ]
        (case maybeActive of
            Just active ->
                List.map (\link -> viewLink link (link.id == active)) links

            Nothing ->
                List.map (\link -> viewLink link False) links
        )


viewLink : Link -> Bool -> Element msg
viewLink link_ active =
    link
        [ Font.bold
        , mouseOver
            [ Background.color (darken lighterGreyColor -0.1)
            ]
        , width fill
        , height (px 50)
        , Border.rounded 10
        , padding 10
        ]
        { url = Route.toString link_.route
        , label =
            el
                (if active then
                    [ Font.color blueColor ]

                 else
                    []
                )
                (text link_.name)
        }
