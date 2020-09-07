module Components.UserChart exposing (view)

import Api.Homework.Analytics
import Axis
import Color
import DateFormat
import Scale exposing (BandConfig, BandScale, ContinuousScale, defaultBandConfig, toRenderable)
import Styling.Colors exposing (chartColors)
import Time
import TypedSvg exposing (font, g, rect, style, svg, text_)
import TypedSvg.Attributes exposing (class, fill, fontFamily, fontSize, stroke, textAnchor, transform, viewBox)
import TypedSvg.Attributes.InPx exposing (height, width, x, y)
import TypedSvg.Core exposing (Svg, text)
import TypedSvg.Types exposing (AnchorAlignment(..), Paint(..), Transform(..), px)


w : Float
w =
    900


h : Float
h =
    300


padding : Float
padding =
    30


xScale : List Api.Homework.Analytics.UserAnalyticsData -> BandScale String
xScale model =
    List.map Tuple.first model
        |> Scale.band { defaultBandConfig | paddingInner = 0.1, paddingOuter = 0.2 } ( 0, w - 2 * padding )


yScale : ContinuousScale Float
yScale =
    Scale.linear ( h - 2 * padding, 0 ) ( 0, 5 )


xAxis : List Api.Homework.Analytics.UserAnalyticsData -> Svg msg
xAxis model =
    -- very nice code lol
    Axis.bottom [] (toRenderable (\x -> x) (xScale model))


yAxis : Svg msg
yAxis =
    Axis.left [ Axis.tickCount 5 ] yScale


column : BandScale String -> Color.Color -> Api.Homework.Analytics.UserAnalyticsData -> Svg msg
column scale color data =
    let
        username =
            Tuple.first data

        value =
            toFloat (Tuple.second data)
    in
    g [ class [ "column" ] ]
        [ rect
            [ x <| Scale.convert scale username
            , y <| Scale.convert yScale value
            , width <| Scale.bandwidth scale
            , height <| h - Scale.convert yScale value - 2 * padding
            , fill (Paint <| color)
            ]
            []
        , text_
            [ x <| Scale.convert (Scale.toRenderable (\x -> x) scale) username
            , y <| Scale.convert yScale value - 5
            , textAnchor AnchorMiddle
            , fill (Paint <| Color.white)
            ]
            [ text <| String.fromFloat value ]
        ]


view : List Api.Homework.Analytics.UserAnalyticsData -> Svg msg
view model =
    svg [ viewBox 0 0 w h ]
        [ style [] [ text """
            .tick line {stroke: #fff}
            .tick text {fill: #fff}
            .domain {stroke: #fff}
            text {font-family: 'Source Sans Pro'}""" ]
        , g
            [ transform
                [ Translate (padding - 1) (h - padding)
                ]
            , fontFamily [ "Source Sans Pro" ]
            , fontSize (px 24)
            ]
            [ xAxis model ]
        , g
            [ transform [ Translate (padding - 1) padding ]
            ]
            [ yAxis ]
        , g
            [ transform
                [ Translate padding padding
                ]
            , class [ "series" ]
            ]
          <|
            List.map (column (xScale model) (Color.rgb255 77 121 167)) model
        ]
