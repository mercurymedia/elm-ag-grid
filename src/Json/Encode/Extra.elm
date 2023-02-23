module Json.Encode.Extra exposing (..)

import Json.Encode


encodeMaybe : (a -> Json.Encode.Value) -> Maybe a -> Json.Encode.Value
encodeMaybe valueEncoder value =
    value
        |> Maybe.map valueEncoder
        |> Maybe.withDefault Json.Encode.null
