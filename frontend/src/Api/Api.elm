module Api.Api exposing (apiAddress)


productionApiAddress : String
productionApiAddress =
    "https://api.hausis.3nt3.de"


localProductionApiAddress : String
localProductionApiAddress =
    "http://localhost/api-global"


localApiAddress : String
localApiAddress =
    "http://localhost/api"


apiAddress : String
apiAddress =
    -- let
    --     _ =
    --         Debug.log "apiAddress" "fix api address back to actual endpoint"
    -- in
    localProductionApiAddress
