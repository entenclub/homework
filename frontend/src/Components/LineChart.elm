module Components.LineChart exposing (mainn)

import Axis
import Color
import Date
import Dict
import List.Extra
import Models
import Path exposing (Path)
import Scale exposing (ContinuousScale)
import Shape
import String exposing (toInt)
import Svg
import Time exposing (millisToPosix)
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


xScale : List ( Time.Posix, Int ) -> ContinuousScale Time.Posix
xScale model =
    let
        onlyTimes =
            List.map (\x -> Time.posixToMillis (Tuple.first x)) model
    in
    case List.minimum onlyTimes of
        Just min ->
            case List.maximum onlyTimes of
                Just max ->
                    Scale.time Time.utc ( 0, w - 2 * padding ) ( Time.millisToPosix min, Time.millisToPosix max )

                _ ->
                    Scale.time Time.utc ( 0, w - 2 * padding ) ( Time.millisToPosix 0, Time.millisToPosix 0 )

        _ ->
            Scale.time Time.utc ( 0, w - 2 * padding ) ( Time.millisToPosix 0, Time.millisToPosix 0 )


yScale : ContinuousScale Float
yScale =
    Scale.linear ( h - 2 * padding, 0 ) ( 0, 10 )


xAxis : List ( Time.Posix, Int ) -> Svg msg
xAxis model =
    Axis.bottom [ Axis.tickCount (List.length model) ] (xScale model)


yAxis : Svg msg
yAxis =
    Axis.left [ Axis.tickCount 5 ] yScale


transformToLineData : List ( Time.Posix, Int ) -> ( Time.Posix, Int ) -> Maybe ( Float, Float )
transformToLineData model ( x, y ) =
    Just ( Scale.convert (xScale model) x, Scale.convert yScale (toFloat y) )


tranfromToAreaData : List ( Time.Posix, Int ) -> ( Time.Posix, Int ) -> Maybe ( ( Float, Float ), ( Float, Float ) )
tranfromToAreaData model ( x, y ) =
    Just
        ( ( Scale.convert (xScale model) x, Tuple.first (Scale.rangeExtent yScale) )
        , ( Scale.convert (xScale model) x, Scale.convert yScale (toFloat y) )
        )


line : List ( Time.Posix, Int ) -> Path
line model =
    List.map (\x -> transformToLineData model x) model
        |> Shape.line Shape.linearCurve


area : List ( Time.Posix, Int ) -> Path
area model =
    List.map (\x -> tranfromToAreaData model x) model
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


markers : List ( Time.Posix, Int ) -> List (Svg msg)
markers model =
    List.map marker (List.map (\x -> transformToLineData model x) model)


backgroundLine : Float -> Float -> Float -> Svg msg
backgroundLine min max yHeight =
    TypedSvg.line
        [ x1 min
        , y1 yHeight
        , x2 max
        , y2 yHeight
        , stroke <| Paint <| Color.rgb255 127 140 141
        ]
        []


backgroundLines : List ( Time.Posix, Int ) -> Time.Posix -> Time.Posix -> List Float -> List (Svg msg)
backgroundLines model min max ticksY =
    List.map (\y -> backgroundLine (Scale.convert (xScale model) min) (Scale.convert (xScale model) max) (Scale.convert yScale y)) ticksY


view : List ( Time.Posix, Int ) -> Date.Date -> Svg msg
view model today =
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
            [ let
                dayTuples =
                    generateDayTuples [] 0 (Time.posixToMillis (dateToPosixTime today))
              in
              g []
                (case List.head dayTuples of
                    Just firstItem ->
                        case List.head (List.reverse dayTuples) of
                            Just lastItem ->
                                backgroundLines model (Tuple.first firstItem) (Tuple.first lastItem) (generateTicks [] -2)

                            Nothing ->
                                [ Svg.text "" ]

                    Nothing ->
                        [ Svg.text "" ]
                )
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


{-| processData takes a list of assignments and returns a list of tuples that look like this
( Time.Posix, Int ) where the first item is the assignments dueDate as UNIX
time and the the second item is the number of assignments
-}
processData : List Models.Assignment -> Date.Date -> List ( Time.Posix, Int )
processData assignments today =
    let
        dayTuples =
            generateDayTuples [] 0 (Time.posixToMillis (dateToPosixTime today))
    in
    List.map
        (\x ->
            ( Tuple.first x
              -- number of assignments whose due date is equal to the specific date?
            , List.length (List.filter (\a -> dateToPosixTime a.dueDate == Tuple.first x) assignments)
            )
        )
        dayTuples


oneDayInMillis : Int
oneDayInMillis =
    86400 * 1000


{-| generates tuples for each day in the last seven days
(Time.Posix, 0)
-}
generateDayTuples : List ( Time.Posix, Int ) -> Int -> Int -> List ( Time.Posix, Int )
generateDayTuples current last todayMillis =
    -- if the maximum of seven days has not been reached, continue
    if List.length current < 7 then
        generateDayTuples
            (List.append
                current
                [ ( millisToPosix (todayMillis + ((last - 1) * oneDayInMillis)), 0 ) ]
            )
            (last + 1)
            todayMillis

    else
        current



-- converts Date.Date to Time.Posix
-- is probably broken in some way


epochStartOffset : Int
epochStartOffset =
    719162


dateToPosixTime : Date.Date -> Time.Posix
dateToPosixTime date =
    Time.millisToPosix ((Date.toRataDie date - epochStartOffset) * (1000 * 60 * 60 * 24) - (1000 * 60 * 60 * 24))


mainn : List Models.Assignment -> Date.Date -> Svg msg
mainn assignments today =
    view (processData assignments today) today



-- From here onwards this is simply example boilerplate.
-- In a real app you would load the data from a server and parse it, perhaps in
-- a separate module.
