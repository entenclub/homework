module Styling.Colors exposing (..)

import Array exposing (Array)
import Element exposing (Color, rgb255)


blueColor : Color
blueColor =
    rgb255 45 156 252


redColor : Color
redColor =
    --rgb255 255 82 96
    rgb255 231 76 60


greenColor : Color
greenColor =
    rgb255 46 204 113


yellowColor : Color
yellowColor =
    rgb255 241 196 15


lighterGreyColor : Color
lighterGreyColor =
    rgb255 29 32 37


darkGreyColor : Color
darkGreyColor =
    rgb255 26 28 33


chartColors : Array Color
chartColors =
    Array.fromList
        [ rgb255 77 121 167
        , rgb255 242 142 43
        , rgb255 225 86 89
        , rgb255 118 183 178
        , rgb255 88 161 78
        , rgb255 237 201 73
        , rgb255 175 121 161
        , rgb255 255 157 167
        , rgb255 156 117 95
        , rgb255 186 176 172
        ]
