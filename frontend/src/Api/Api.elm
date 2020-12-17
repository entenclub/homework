module Api.Api exposing (apiAddress)


apiAddress =
    let
        debug =
            Debug.log "apiAddress" "fix api address back to actual endpoint"
    in
    "http://localhost:8004"
