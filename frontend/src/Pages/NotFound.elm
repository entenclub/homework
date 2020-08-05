module Pages.NotFound exposing (Model, Msg, Params, page)

import Element exposing (..)
import Element.Font as Font
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


view : Url Params -> Document Msg
view { params } =
    { title = "404"
    , body =
        [ column
            [ centerX
            , centerY
            , Font.family
                [ Font.typeface "Merriweather"
                , Font.serif
                ]
            , spacing 20
            ]
            [ el [ centerX, Font.size 60 ] (text "no page lol")
            , el [ centerX ] (text "Error 404. Go somewhere else")
            ]
        ]
    }
