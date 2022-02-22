module Components.Link exposing (main)

import Browser
import Html exposing (Html, a, text)
import Html.Attributes exposing (href)
import Json.Decode


main : Program Json.Decode.Value Model msg
main =
    Browser.element
        { init = \flags -> ( decodeFlags flags, Cmd.none )
        , view = view
        , update = \_ model -> ( model, Cmd.none )
        , subscriptions = always Sub.none
        }



-- MODEL


type alias Model =
    Result Json.Decode.Error Data


type alias Data =
    { url : String
    , linkName : String
    }



-- VIEW


view : Model -> Html msg
view model =
    case model of
        Result.Ok data ->
            a [ href data.url ] [ text data.linkName ]

        Result.Err _ ->
            text ""



-- Decoder


dataDecoder : Json.Decode.Decoder Data
dataDecoder =
    Json.Decode.map2 Data
        (Json.Decode.at [ "url" ] Json.Decode.string)
        (Json.Decode.at [ "linkName" ] Json.Decode.string)


{-| Receives the params from the cellRenderer.

The value of the `details` cell is an encoded value.

-}
decodeFlags : Json.Decode.Value -> Model
decodeFlags value =
    let
        decodedDetails =
            Json.Decode.at [ "data", "details" ] Json.Decode.string
                |> Json.Decode.andThen detailStringDecoder
    in
    Json.Decode.decodeValue decodedDetails value


detailStringDecoder : String -> Json.Decode.Decoder Data
detailStringDecoder input =
    case Json.Decode.decodeString dataDecoder input of
        Result.Ok data ->
            Json.Decode.succeed data

        Result.Err err ->
            Json.Decode.fail (Json.Decode.errorToString err)
