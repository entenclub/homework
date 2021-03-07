module Api.Api exposing (apiAddress)


productionApiAddress =
    "https://api.hausis.3nt3.de"

localApiAddress =
    "http://localhost:8004"

apiAddress =
    let
        debug =
            Debug.log "apiAddress" "fix api address back to actual endpoint"
    in
    localApiAddress
