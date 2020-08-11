module Pages.Register exposing (Model, Msg, Params, page)

import Api
import Api.Homework.User
import Api.Homework.UsernameTaken
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border exposing (rounded)
import Element.Font as Font
import Element.Input as Input
import Html exposing (input)
import Material.Icons as Icons
import Material.Icons.Types exposing (Coloring(..))
import Shared
import Spa.Document exposing (Document)
import Spa.Generated.Route as Route
import Spa.Page as Page exposing (Page)
import Spa.Url exposing (Url)
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


type alias Errors =
    { username : Maybe String
    , password : Maybe String
    , email : Maybe String
    }


type alias Model =
    { usernameInput : String
    , passwordInput : String
    , validatePasswordInput : String
    , emailInput : String
    , errors : Errors
    , usernameTakenStatus : Api.Data Bool
    , registrationStatus : Api.Data Shared.User
    , url : Url Params
    }


type Msg
    = UsernameInput String
    | PasswordInput String
    | ValidatePasswordInput String
    | EmailInput String
    | GotUsernameTaken (Api.Data Bool)
    | GotRegistrationData (Api.Data Shared.User)
    | Register


init : Shared.Model -> Url Params -> ( Model, Cmd Msg )
init _ url =
    ( { usernameInput = ""
      , passwordInput = ""
      , validatePasswordInput = ""
      , emailInput = ""
      , errors = { username = Nothing, password = Nothing, email = Nothing }
      , usernameTakenStatus = Api.NotAsked
      , registrationStatus = Api.NotAsked
      , url = url
      }
    , Cmd.none
    )


validateEmailInput : String -> Maybe String
validateEmailInput input =
    if String.contains "@" input then
        Nothing

    else if input == "" then
        Just "no email address specified"

    else
        Just "not a valid address"


validateUsernameInput : String -> Maybe String
validateUsernameInput input =
    if input == "" then
        Just "no username specified"

    else if String.contains " " input then
        Just "no spaces allowed"

    else
        Nothing


validatePasswordInput : String -> String -> Maybe String
validatePasswordInput input validationInput =
    if String.length input < 8 then
        Just "password too short"

    else if validationInput /= input then
        Just "passwords don't match"

    else
        Nothing


setUsernameError : Errors -> Maybe String -> Errors
setUsernameError original newError =
    { original | username = newError }


setEmailError : Errors -> Maybe String -> Errors
setEmailError original newError =
    { original | email = newError }


setPasswordError : Errors -> Maybe String -> Errors
setPasswordError original newError =
    { original | password = newError }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UsernameInput input ->
            if String.length input > 0 then
                ( { model
                    | usernameInput = input
                    , errors = setUsernameError model.errors (validateUsernameInput input)
                  }
                , Api.Homework.UsernameTaken.usernameTaken input { onResponse = GotUsernameTaken }
                )

            else
                ( { model
                    | usernameInput = input
                    , errors = setUsernameError model.errors (validateUsernameInput input)
                    , usernameTakenStatus = Api.NotAsked
                  }
                , Cmd.none
                )

        PasswordInput input ->
            ( { model
                | passwordInput = input
                , errors = setPasswordError model.errors (validatePasswordInput input model.validatePasswordInput)
              }
            , Cmd.none
            )

        ValidatePasswordInput input ->
            ( { model
                | validatePasswordInput = input
                , errors = setPasswordError model.errors (validatePasswordInput model.passwordInput input)
              }
            , Cmd.none
            )

        EmailInput input ->
            ( { model
                | emailInput = input
                , errors = setEmailError model.errors (validateEmailInput input)
              }
            , Cmd.none
            )

        GotUsernameTaken data ->
            ( { model | usernameTakenStatus = data }, Cmd.none )

        GotRegistrationData data ->
            case data of
                Api.Success _ ->
                    ( model, Utils.Route.navigate model.url.key Route.Dashboard )

                _ ->
                    ( { model | registrationStatus = data }, Cmd.none )

        Register ->
            ( model
            , Api.Homework.User.register
                { username = model.usernameInput
                , password = model.passwordInput
                , email = Just model.emailInput
                }
                { onResponse = GotRegistrationData }
            )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


load : Shared.Model -> Model -> ( Model, Cmd msg )
load shared model =
    ( model, Cmd.none )


save : Model -> Shared.Model -> Shared.Model
save model shared =
    case model.registrationStatus of
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
    { title = "Register"
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
                        (text "Register")
                    , row [ spacing 10 ]
                        [ column [ width (fillPortion 20) ]
                            [ viewInputError model "email"
                            , Input.email inputStyle
                                { label = Input.labelHidden "email"
                                , placeholder = Just (Input.placeholder [] (text "enter email address"))
                                , onChange = EmailInput
                                , text = model.emailInput
                                }
                            ]
                        , column [ width (fillPortion 18) ]
                            [ Input.text inputStyle
                                { label = Input.labelHidden "username"
                                , placeholder = Just (Input.placeholder [] (text "enter username"))
                                , onChange = UsernameInput
                                , text = model.usernameInput
                                }
                            ]
                        , el
                            [ width (px 55)
                            , height (px 55)
                            , Background.color (rgb 1 1 1)
                            , Border.rounded 3
                            , height fill
                            , Border.solid
                            , Border.width 1
                            , Border.color (rgb 0.7 0.7 0.7)
                            ]
                            (viewUsernameTaken model)
                        ]
                    , column [ width fill, spacing 5 ]
                        [ viewInputError model "password"
                        , passwordStrengthIndicator model.passwordInput
                        , Input.newPassword
                            inputStyle
                            { label = Input.labelHidden "password"
                            , placeholder = Just (Input.placeholder [] (text "enter password"))
                            , onChange = PasswordInput
                            , text = model.passwordInput
                            , show = False
                            }
                        ]
                    , Input.currentPassword inputStyle
                        { label = Input.labelHidden "validate password"
                        , placeholder = Just (Input.placeholder [] (text "repeat password"))
                        , onChange = ValidatePasswordInput
                        , text = model.validatePasswordInput
                        , show = False
                        }
                    , Input.button
                        [ Background.color omgSoGreatColor
                        , Font.size 20
                        , Font.color (rgb 1 1 1)
                        , Border.rounded 5
                        , centerX
                        , paddingXY 30 15
                        , Font.bold
                        ]
                        { label = viewRegistrationButton model
                        , onPress = Just Register
                        }
                    ]
                )
            ]
        ]
    }


viewInputError : Model -> String -> Element Msg
viewInputError model inputName =
    if inputName == "email" then
        inputErrorMessage model.errors.email

    else if inputName == "username" then
        inputErrorMessage model.errors.username

    else if inputName == "password" then
        inputErrorMessage model.errors.password

    else
        Element.none


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


inputErrorMessage : Maybe String -> Element Msg
inputErrorMessage error =
    case error of
        Just errorMessage ->
            el [ Font.color errorColor ] (text ("Error: " ++ errorMessage))

        Nothing ->
            el [ Font.color errorColor ] (text "")


getPasswordStrengthColor : Int -> Color
getPasswordStrengthColor length =
    if length < 8 then
        errorColor

    else if length < 12 then
        warningColor

    else if length < 20 then
        greenColor

    else
        omgSoGreatColor


passwordStrengthIndicator : String -> Element Msg
passwordStrengthIndicator password =
    el
        [ width fill
        , height (px 10)
        , Background.color (getPasswordStrengthColor (String.length password))
        , Border.rounded 5
        ]
        Element.none


viewUsernameTaken : Model -> Element Msg
viewUsernameTaken model =
    el [ centerX, centerY, width shrink, height fill ]
        (let
            size =
                48
         in
         case model.usernameTakenStatus of
            Api.Success taken ->
                if taken then
                    el [ centerX, centerY, Font.color errorColor ]
                        (html (Icons.close size Inherit))

                else
                    el [ centerX, centerY, Font.color darkGreenColor ] (html (Icons.check size Inherit))

            Api.Failure _ ->
                el [ centerX, centerY ] (html (Icons.error (round (size * 0.8)) Inherit))

            Api.Loading ->
                el [ centerX, centerY ] (html (Icons.hourglass_bottom size Inherit))

            Api.NotAsked ->
                el [] Element.none
        )


viewRegistrationButton : Model -> Element Msg
viewRegistrationButton model =
    let
        size =
            42
    in
    el []
        (case model.registrationStatus of
            Api.Success _ ->
                el [ centerX, centerY, Font.color darkGreenColor ] (html (Icons.check size Inherit))

            Api.Loading ->
                el [ centerX, centerY ] (html (Icons.hourglass_bottom size Inherit))

            Api.Failure _ ->
                el [ centerX, centerY, Font.color errorColor ]
                    (html (Icons.close size Inherit))

            Api.NotAsked ->
                text "register"
        )
