module Api.Api exposing (apiAddress)


productionApiAddress : String
productionApiAddress =
    "https://api.hausis.3nt3.de"


localApiAddress : String
localApiAddress =
    "http://localhost:8005"


apiAddress : String
apiAddress =
    let
        _ =
            Debug.log "apiAddress" "fix api address back to actual endpoint"
    in
    localApiAddress
