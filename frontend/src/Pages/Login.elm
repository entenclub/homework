module Pages.Login exposing (Model, Msg, Params, page)

import Api exposing (HttpError(..), errorToString)
import Api.Homework.User
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border exposing (rounded)
import Element.Font as Font
import Element.Input as Input
import Material.Icons as Icons
import Material.Icons.Types exposing (Coloring(..))
import Models
import Shared
import Spa.Document exposing (Document)
import Spa.Generated.Route as Route
import Spa.Page as Page exposing (Page)
import Spa.Url exposing (Url)
import Utils.OnEnter exposing (onEnter)
import Utils.Route


page : Page Params Model Msg
page =
    Page.application
        { init = init
        , subscriptions = subscriptions
        , update = update
        , view = view
        , save = save
        , load = load
        }


type alias Params =
    ()


type alias Model =
    { usernameInput : String
    , passwordInput : String
    , loginStatus : Api.Data Models.User
    , url : Url Params
    }


type Msg
    = UsernameInput String
    | PasswordInput String
    | GotLoginData (Api.Data Models.User)
    | Login


init : Shared.Model -> Url Params -> ( Model, Cmd Msg )
init _ url =
    ( { usernameInput = ""
      , passwordInput = ""
      , loginStatus = Api.NotAsked
      , url = url
      }
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UsernameInput input ->
            ( { model
                | usernameInput = input
              }
            , Cmd.none
            )

        PasswordInput input ->
            ( { model
                | passwordInput = input
              }
            , Cmd.none
            )

        GotLoginData data ->
            case data of
                Api.Success _ ->
                    ( { model | loginStatus = data }, Utils.Route.navigate model.url.key Route.Dashboard )

                _ ->
                    ( { model | loginStatus = data }, Cmd.none )

        Login ->
            ( model
            , Api.Homework.User.login
                { username = model.usernameInput
                , password = model.passwordInput
                , email = Nothing
                }
                { onResponse = GotLoginData }
            )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


load : Shared.Model -> Model -> ( Model, Cmd msg )
load shared model =
    ( model, Cmd.none )


save : Model -> Shared.Model -> Shared.Model
save model shared =
    case model.loginStatus of
        Api.Success user ->
            { shared | user = Just user }

        _ ->
            shared


inputStyle : List (Attribute msg)
inputStyle =
    [ Font.family
        [ Font.typeface "Noto Serif"
        , Font.serif
        ]
    , Font.size 25
    ]


view : Model -> Document Msg
view model =
    { title = "Login"
    , body =
        [ column [ width fill, height fill ]
            [ el
                [ centerX
                , centerY
                ]
                (column
                    [ Background.color (rgb255 230 230 230)
                    , padding 50
                    , spacing 10
                    ]
                    [ el
                        [ Font.family
                            [ Font.typeface "Noto Serif"
                            , Font.serif
                            ]
                        , Font.size 40
                        ]
                        (text "Login")
                    , column [ width fill ]
                        [ Input.text (inputStyle ++ [ onEnter Login ])
                            { label = Input.labelHidden "username"
                            , placeholder = Just (Input.placeholder [] (text "enter username"))
                            , onChange = UsernameInput
                            , text = model.usernameInput
                            }
                        ]
                    , column [ width fill, spacing 5 ]
                        [ Input.currentPassword
                            (inputStyle ++ [ onEnter Login ])
                            { label = Input.labelHidden "password"
                            , placeholder = Just (Input.placeholder [] (text "enter password"))
                            , onChange = PasswordInput
                            , text = model.passwordInput
                            , show = False
                            }
                        ]
                    , Input.button
                        [ Background.color omgSoGreatColor
                        , Font.size 20
                        , Font.color (rgb 1 1 1)
                        , Border.rounded 5
                        , centerX
                        , paddingXY 30 15
                        , Font.bold
                        ]
                        { label = viewLoginButton model
                        , onPress = Just Login
                        }
                    ]
                )
            ]
        ]
    }


errorColor : Color
errorColor =
    rgb255 255 82 82


warningColor : Color
warningColor =
    rgb255 255 177 66


greenColor : Color
greenColor =
    rgb255 46 204 113


darkGreenColor : Color
darkGreenColor =
    rgb255 39 174 96


omgSoGreatColor : Color
omgSoGreatColor =
    rgb255 52 172 224


viewLoginButton : Model -> Element Msg
viewLoginButton model =
    let
        size =
            42
    in
    el []
        (case model.loginStatus of
            Api.Success _ ->
                el [ centerX, centerY, Font.color darkGreenColor ] (html (Icons.check size Inherit))

            Api.Loading ->
                el [ centerX, centerY ] (html (Icons.hourglass_bottom size Inherit))

            Api.Failure _ ->
                el [ centerX, centerY, Font.color errorColor ]
                    (html (Icons.close size Inherit))

            Api.NotAsked ->
                el [ Font.family [ Font.typeface "Source Sans Pro" ] ] (text "Login")
        )
