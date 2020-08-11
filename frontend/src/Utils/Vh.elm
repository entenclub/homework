module Utils.Vh exposing (vh, vw)


vw : Int -> Float -> Int
vw fullWidth units =
    round ((toFloat fullWidth / 100) * units)


vh : Int -> Float -> Int
vh fullHeight units =
    round ((toFloat fullHeight / 100) * units)
