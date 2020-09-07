module Components.CourseChart exposing (view)

import Api.Homework.Analytics
import Array exposing (Array)
import Color exposing (Color, rgb)
import Path
import Shape exposing (defaultPieConfig)
import TypedSvg exposing (g, svg, text_)
import TypedSvg.Attributes exposing (color, dy, fill, fontFamily, fontSize, fontWeight, stroke, textAnchor, transform, viewBox)
import TypedSvg.Attributes.InPx exposing (height, width)
import TypedSvg.Core exposing (Svg, text)
import TypedSvg.Types exposing (AnchorAlignment(..), FontWeight(..), Paint(..), Transform(..), em, pt, px)


w : Float
w =
    990


h : Float
h =
    504


colors : Array Color
colors =
    Array.fromList
        [ Color.rgb255 77 121 167
        , Color.rgb255 242 142 43
        , Color.rgb255 225 86 89
        , Color.rgb255 118 183 178
        , Color.rgb255 88 161 78
        , Color.rgb255 237 201 73
        , Color.rgb255 175 121 161
        , Color.rgb255 255 157 167
        , Color.rgb255 156 117 95
        , Color.rgb255 186 176 172
        ]


radius : Float
radius =
    min w h / 2


view : List Api.Homework.Analytics.CourseAnalyticsData -> Svg msg
view model =
    let
        pieData =
            Shape.pie { defaultPieConfig | outerRadius = radius } (List.map toFloat (List.map Tuple.second model))

        makeSlice index datum =
            Path.element (Shape.arc datum) [ fill <| Paint <| Maybe.withDefault Color.black <| Array.get index colors, stroke <| Paint Color.white ]

        makeLabel slice ( label, value ) =
            let
                ( x, y ) =
                    Shape.centroid { slice | innerRadius = radius - 40, outerRadius = radius - 40 }
            in
            text_
                [ transform [ Translate x y ]
                , dy (em 0.35)
                , textAnchor AnchorMiddle
                , fill <| Paint Color.white
                , fontSize (pt 24)
                , fontFamily [ "Source Sans Pro" ]
                , fontWeight FontWeightBold
                ]
                [ text label ]
    in
    svg [ viewBox 0 0 w h ]
        [ g [ transform [ Translate (w / 2) (h / 2) ] ]
            [ g [] <| List.indexedMap makeSlice pieData
            , g [] <| List.map2 makeLabel pieData model
            ]
        ]



-- data : List ( String, Float )
-- data =
--     [ ( "/notifications", 2704659 )
--     , ( "/about", 4499890 )
--     , ( "/product", 2159981 )
--     , ( "/blog", 3853788 )
--     , ( "/shop", 14106543 )
--     , ( "/profile", 8819342 )
--     , ( "/", 612463 )
--     ]
