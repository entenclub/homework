module Utils.Darken exposing (darken)

import Element exposing (Color, rgb, toRgb)


darken : Color -> Float -> Color
darken original factor =
    let
        extracted =
            toRgb original

        r =
            extracted.red

        g =
            extracted.green

        b =
            extracted.blue
    in
    rgb (r - factor) (g - factor) (b - factor)
