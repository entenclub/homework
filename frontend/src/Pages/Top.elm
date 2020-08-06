module Pages.Top exposing (Model, Msg, Params, page)

import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Spa.Document exposing (Document)
import Spa.Page as Page exposing (Page)
import Spa.Url exposing (Url)


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
                    , el [ centerX, Font.size 20 ]
                        (link
                            [ padding 15
                            , Background.color primaryColor
                            , Border.rounded 7
                            , Font.color (rgb255 255 255 255)
                            , Font.family
                                [ Font.typeface "Roboto"
                                , Font.sansSerif
                                ]
                            ]
                            { url = "/register", label = text "Register now" }
                        )
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
                            [ text "Adipisicing ut culpa in ex Lorem aliqua aliqua aute qui. Cupidatat proident mollit id ad sunt veniam veniam qui sit eiusmod proident. Officia do adipisicing magna laborum excepteur.Qui Lorem aliqua Lorem sint fugiat pariatur nostrud. Culpa deserunt minim laboris aliquip nisi cillum et fugiat ea id adipisicing in. Veniam esse irure cillum incididunt. Cillum consequat mollit aute laboris adipisicing laboris id sint nisi."
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
