module Pages.Top exposing (Model, Msg, Params, page)

import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import I18Next exposing (Translations)
import Shared
import Spa.Document exposing (Document)
import Spa.Page as Page exposing (Page)
import Spa.Url exposing (Url)
import Styling.Colors exposing (blueColor, darkGreyColor, redColor)
import Translations.Global
import Translations.Pages.Top


type alias Params =
    ()


type alias Model =
    { url : Url Params
    , translations : I18Next.Translations
    }


type alias Msg =
    Never


page : Page Params Model Msg
page =
    Page.application
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        , save = save
        , load = load
        }


init : Shared.Model -> Url Params -> ( Model, Cmd Msg )
init shared url =
    ( { url = url, translations = shared.translations }, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


save : Model -> Shared.Model -> Shared.Model
save model shared =
    shared


load : Shared.Model -> Model -> ( Model, Cmd Msg )
load shared model =
    ( model, Cmd.none )



-- VIEW


primaryColor : Color
primaryColor =
    rgb255 52 172 224


darkGrey : Color
darkGrey =
    rgb255 61 61 61


view : Model -> Document Msg
view model =
    { title = "dwb?"
    , body =
        [ column [ width fill, height fill ]
            [ -- heading
              el
                [ Font.family
                    [ Font.typeface "Noto Serif"
                    , Font.serif
                    ]
                , height (fill |> minimum 1000)
                , width fill
                ]
                (column [ centerX, centerY, spacing 10 ]
                    [ el [ centerX, Font.size 80 ] (text (Translations.Global.title model.translations))
                    , el
                        [ centerX
                        , Font.size 30
                        , Font.family [ Font.typeface "Source Sans Pro" ]
                        , Font.bold
                        , Background.color blueColor
                        , Font.color (rgb 1 1 1)
                        , padding 5
                        , Border.rounded 5
                        ]
                        (text "Beta v0.7")
                    ]
                )

            -- about
            , el
                [ Font.family
                    [ Font.typeface "Noto Serif"
                    , Font.serif
                    ]
                , width fill
                , Background.color darkGreyColor
                , Font.color (rgb 1 1 1)
                , height fill
                ]
                (column [ padding 100, spacing 10 ]
                    [ el [ Font.size 60 ]
                        (text <| Translations.Pages.Top.aboutTitle model.translations)
                    , el
                        []
                        (paragraph [ Font.size 24 ]
                            [ text <| Translations.Pages.Top.aboutContent model.translations
                            ]
                        )
                    ]
                )
            ]
        ]
    }
