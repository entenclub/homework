module Pages.Top exposing (Model, Msg, Params, page)

import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Spa.Document exposing (Document)
import Spa.Page as Page exposing (Page)
import Spa.Url exposing (Url)
import Styling.Colors exposing (redColor)


type alias Params =
    ()


type alias Model =
    Url Params


type alias Msg =
    Never


page : Page Params Model Msg
page =
    Page.static
        { view = view
        }



-- VIEW


primaryColor : Color
primaryColor =
    rgb255 52 172 224


darkGrey : Color
darkGrey =
    rgb255 61 61 61


view : Url Params -> Document Msg
view { params } =
    { title = "dwb?"
    , body =
        [ column [ width fill ]
            [ -- heading
              el
                [ Font.family
                    [ Font.typeface "Noto Serif"
                    , Font.serif
                    ]
                , height (px 800)
                , width fill
                ]
                (column [ centerX, centerY, spacing 10 ]
                    [ el [ centerX, Font.size 80 ] (text "Homework Organizer")
                    , el
                        [ centerX
                        , Font.size 30
                        , Font.family [ Font.typeface "Source Sans Pro" ]
                        , Font.bold
                        , Background.color redColor
                        , Font.color (rgb 1 1 1)
                        , padding 5
                        , Border.rounded 5
                        ]
                        (text "Beta v0.2")
                    ]
                )

            -- about
            , el
                [ Font.family
                    [ Font.typeface "Noto Serif"
                    , Font.serif
                    ]
                , width fill
                , Background.color darkGrey
                , Font.color (rgb 1 1 1)
                ]
                (column [ padding 100, spacing 10 ]
                    [ el [ Font.size 60 ]
                        (text "About")
                    , el
                        []
                        (paragraph [ Font.size 24 ]
                            [ text "This is a tool created to help you organize homework assignments collaboratively with your classmates."
                            ]
                        )
                    ]
                )

            -- call to action?
            , el []
                (column []
                    [ text ""
                    ]
                )
            ]
        ]
    }
