module Api.Homework.Analytics exposing (..)

import Api
import Api.Api exposing (apiAddress)
import Http
import Json.Decode as Json


type alias CourseAnalyticsData =
    ( String, Int )


courseAnalyticsDecoder : Json.Decoder CourseAnalyticsData
courseAnalyticsDecoder =
    Json.map2 Tuple.pair
        (Json.index 0 Json.string)
        (Json.index 1 Json.int)


getCourseAnalytics : { onResponse : Api.Data (List CourseAnalyticsData) -> msg } -> Cmd msg
getCourseAnalytics options =
    Http.riskyRequest
        { url = apiAddress ++ "/analytics/courses?tuples"
        , method = "GET"
        , headers = []
        , tracker = Nothing
        , timeout = Nothing
        , expect = Api.expectJson options.onResponse (Json.at [ "content" ] (Json.list courseAnalyticsDecoder))
        , body = Http.emptyBody
        }
