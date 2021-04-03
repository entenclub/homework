module Api.Api exposing (apiAddress)

import Svg.Attributes exposing (local)


productionApiAddress =
    "https://api.hausis.3nt3.de"


localApiAddress =
    "http://localhost:8005"


apiAddress =
    let
        debug =
            Debug.log "apiAddress" "fix api address back to actual endpoint"
    in
    localApiAddress
