port module Components.Editor exposing (config, main)

import Browser
import Css
import Html.Styled exposing (Html, button, div, text)
import Html.Styled.Attributes exposing (css, id, style, type_)
import Html.Styled.Events exposing (onClick)
import Json.Encode


{-| This port will notify the main application about the button clicked.

The button click doesn't need to be propagated to the main application if
only internal state shall be changed.

-}
port currentValue : String -> Cmd msg


main : Program Flags Model Msg
main =
    Browser.element
        { init = initialModel
        , view = view >> Html.Styled.toUnstyled
        , update = update
        , subscriptions = subscriptions
        }


{-| Reading the current `value` from the grid params and transforming it into a proper format.
-}
initialModel : Flags -> ( Model, Cmd Msg )
initialModel flags =
    ( { values = toValues flags.value }
    , Cmd.none
    )



-- MODEL


type alias Flags =
    { value : String
    }


type alias Model =
    { values : List String
    }


type Msg
    = AddedInfoValue String



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        AddedInfoValue info ->
            let
                updatedModel =
                    { model | values = info :: model.values }
            in
            ( updatedModel, currentValue (formatValue updatedModel.values) )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Model -> Html Msg
view model =
    div [ css [ Css.padding2 (Css.px 8) (Css.px 8) ] ]
        [ button [ type_ "button", onClick (AddedInfoValue "foo") ] [ text "Foo" ]
        ]


config : { componentName : String, componentParams : Maybe Json.Encode.Value }
config =
    { componentName = "editor", componentParams = Nothing }


formatValue : List String -> String
formatValue values =
    String.join ", " values


toValues : String -> List String
toValues value =
    value
        |> String.split ","
        |> List.map String.trim
        |> List.filter (not << String.isEmpty)
