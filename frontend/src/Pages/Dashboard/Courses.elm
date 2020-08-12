module Pages.Dashboard.Courses exposing (Model, Msg, Params, page)

import Element exposing (..)
import Spa.Document exposing (Document)
import Spa.Generated.Route as Route exposing (Route)
import Spa.Page as Page exposing (Page)
import Spa.Url exposing (Url)


type alias Model =
    ()


type alias Msg =
    ()


type alias Params =
    ()


page : Page Params Model Msg
page =
    Page.sandbox
        { init = init
        , update = update
        , view = view
        }


init : Url Params -> Model
init url =
    ()


update : Msg -> Model -> Model
update msg model =
    model


view : Model -> Document Msg
view model =
    { title = "courses"
    , body = [ none ]
    }
