module Components.LineChart exposing (main)

import Axis
import Color
import Path exposing (Path)
import Scale exposing (ContinuousScale)
import Shape
import Svg
import Time
import TypedSvg exposing (circle, g, path, style, svg)
import TypedSvg.Attributes exposing (class, d, fill, stroke, transform, viewBox)
import TypedSvg.Attributes.InPx exposing (cx, cy, r, strokeWidth, x1, x2, y1, y2)
import TypedSvg.Core exposing (Svg, text)
import TypedSvg.Types exposing (Paint(..), Transform(..))


blueColor : Float -> Color.Color
blueColor alpha =
    Color.rgba (45 / 255) (156 / 255) (252 / 255) alpha


w : Float
w =
    500


h : Float
h =
    200


padding : Float
padding =
    30


xScale : ContinuousScale Time.Posix
xScale =
    Scale.time Time.utc ( 0, w - 2 * padding ) ( Time.millisToPosix 1617027188, Time.millisToPosix 1616512388 )


yScale : ContinuousScale Float
yScale =
    Scale.linear ( h - 2 * padding, 0 ) ( 0, 10 )


xAxis : List ( Time.Posix, Float ) -> Svg msg
xAxis model =
    Axis.bottom [ Axis.tickCount (List.length model) ] xScale


yAxis : Svg msg
yAxis =
    Axis.left [ Axis.tickCount 5 ] yScale


transformToLineData : ( Time.Posix, Float ) -> Maybe ( Float, Float )
transformToLineData ( x, y ) =
    Just ( Scale.convert xScale x, Scale.convert yScale y )


tranfromToAreaData : ( Time.Posix, Float ) -> Maybe ( ( Float, Float ), ( Float, Float ) )
tranfromToAreaData ( x, y ) =
    Just
        ( ( Scale.convert xScale x, Tuple.first (Scale.rangeExtent yScale) )
        , ( Scale.convert xScale x, Scale.convert yScale y )
        )


line : List ( Time.Posix, Float ) -> Path
line model =
    List.map transformToLineData model
        |> Shape.line Shape.linearCurve


area : List ( Time.Posix, Float ) -> Path
area model =
    List.map tranfromToAreaData model
        |> Shape.area Shape.linearCurve


marker : Maybe ( Float, Float ) -> Svg msg
marker data =
    case data of
        Just x ->
            circle
                [ r 3
                , cx (Tuple.first x)
                , cy (Tuple.second x)
                , fill <| Paint <| blueColor 1.0
                ]
                []

        Nothing ->
            Svg.text ""


markers : List ( Time.Posix, Float ) -> List (Svg msg)
markers model =
    List.map marker (List.map transformToLineData model)


backgroundLine : Float -> Svg msg
backgroundLine yHeight =
    TypedSvg.line
        [ x1 (Scale.convert xScale (Time.millisToPosix 1617027188))
        , y1 yHeight
        , x2 (Scale.convert xScale (Time.millisToPosix 1616512388))
        , y2 yHeight
        , stroke <| Paint <| Color.rgb255 127 140 141
        ]
        []


backgroundLines : List Float -> List (Svg msg)
backgroundLines ticksY =
    List.map (\y -> backgroundLine (Scale.convert yScale y)) ticksY


view : List ( Time.Posix, Float ) -> Svg msg
view model =
    svg [ viewBox 0 0 w h ]
        [ style [] [ text """.domain {display:none}
        .tick line {display: none}
        .tick text {fill: #7f8c8d}
        """ ]
        , g
            [ transform [ Translate (padding - 1) (h - padding) ]
            , class [ "xAxis" ]
            ]
            [ xAxis model ]
        , g [ transform [ Translate (padding - 1) padding ] ]
            [ yAxis ]
        , g [ transform [ Translate padding padding ], class [ "series" ] ]
            [ g [] (backgroundLines (generateTicks [] -2))
            , Path.element (area model) [ strokeWidth 2, fill <| Paint <| blueColor 0.3 ]
            , Path.element (line model) [ stroke <| Paint <| blueColor 1.0, strokeWidth 2, fill PaintNone ]
            , g []
                (markers model)
            ]
        ]


generateTicks : List Float -> Float -> List Float
generateTicks current last =
    if last < 10 then
        generateTicks (List.append current [ last + 2 ]) (last + 2)

    else
        current


mockupData : List ( Time.Posix, Float )
mockupData =
    [ ( Time.millisToPosix 1617027188, 1.0 )
    , ( Time.millisToPosix 1616940788, 2.0 )
    , ( Time.millisToPosix 1616857988, 7.0 )
    , ( Time.millisToPosix 1616771588, 1.0 )
    , ( Time.millisToPosix 1616685188, 5.0 )
    , ( Time.millisToPosix 1616598788, 1.0 )
    , ( Time.millisToPosix 1616512388, 3.0 )
    ]


main =
    view mockupData



-- From here onwards this is simply example boilerplate.
-- In a real app you would load the data from a server and parse it, perhaps in
-- a separate module.
