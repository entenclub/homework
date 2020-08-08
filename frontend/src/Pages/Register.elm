module Pages.Register exposing (Model, Msg, Params, page)

import Element exposing (..)
import Element.Background as Background
import Element.Border as Border exposing (rounded)
import Element.Font as Font
import Element.Input as Input
import Html exposing (input)
import Http
import Json.Decode as Json
import Material.Icons as Icons
import Material.Icons.Types exposing (Coloring(..))
import Spa.Document exposing (Document)
import Spa.Page as Page exposing (Page)
import Spa.Url exposing (Url)


page : Page Params Model Msg
page =
    Page.element
        { init = init
        , subscriptions = subscriptions
        , update = update
        , view = view
        }


type alias Params =
    ()


type alias Errors =
    { username : Maybe String
    , password : Maybe String
    , email : Maybe String
    }


type UsernameTakenStatus
    = Success Bool
    | Inactive
    | Failure
    | Loading


type alias Model =
    { usernameInput : String
    , passwordInput : String
    , validatePasswordInput : String
    , emailInput : String
    , errors : Errors
    , usernameTakenStatus : UsernameTakenStatus
    }


type Msg
    = UsernameInput String
    | PasswordInput String
    | ValidatePasswordInput String
    | EmailInput String
    | GotUsernameTaken (Result Http.Error Bool)
    | Register


init : Url Params -> ( Model, Cmd Msg )
init _ =
    ( { usernameInput = ""
      , passwordInput = ""
      , validatePasswordInput = ""
      , emailInput = ""
      , errors = { username = Nothing, password = Nothing, email = Nothing }
      , usernameTakenStatus = Inactive
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
                , usernameTakenRequest input
                )

            else
                ( { model
                    | usernameInput = input
                    , errors = setUsernameError model.errors (validateUsernameInput input)
                    , usernameTakenStatus = Inactive
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

        GotUsernameTaken result ->
            case result of
                Ok taken ->
                    ( { model | usernameTakenStatus = Success taken }, Cmd.none )

                Err _ ->
                    ( { model | usernameTakenStatus = Failure }, Cmd.none )

        _ ->
            ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


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
                        , placeholder = Just (Input.placeholder [] (text "validate password"))
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
                        { label = text "register"
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
            Success taken ->
                if taken then
                    el [ centerX, centerY, Font.color errorColor ]
                        (html (Icons.close size Inherit))

                else
                    el [ centerX, centerY, Font.color greenColor ] (html (Icons.check size Inherit))

            Failure ->
                el [ centerX, centerY ] (html (Icons.error (round (size * 0.8)) Inherit))

            Loading ->
                el [ centerX, centerY ] (html (Icons.hourglass_bottom size Inherit))

            Inactive ->
                el [] Element.none
        )


usernameTakenRequest : String -> Cmd Msg
usernameTakenRequest username =
    Http.get
        { url = "http://localhost:5000/username-taken/" ++ username
        , expect = Http.expectJson GotUsernameTaken usernameTakenDecoder
        }


usernameTakenDecoder : Json.Decoder Bool
usernameTakenDecoder =
    Json.field "content" Json.bool
