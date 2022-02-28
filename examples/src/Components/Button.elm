port module Components.Button exposing (main)

import Browser
import Html exposing (Html, button, text)
import Html.Attributes exposing (id, style, type_)
import Html.Events exposing (onClick)


{-| componentRefresh port allows to update the model of the component
when the params updated and the cellRenderer needs to refresh.

This can be ignored when only static data is displayed and the component
will never need to react to component updates.

-}
port componentRefresh : (Flags -> msg) -> Sub msg


{-| This port will notify the main application about the button clicked.

The button click doesn't need to be propagated to the main application if
only internal state shall be changed.

-}
port onButtonClick : Int -> Cmd msg


main : Program Flags Model Msg
main =
    Browser.element
        { init = initialModel
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


{-| Reading the `data` and `componentParams` from the cellRenderer params
and also initializing an internal state variable for the component.
-}
initialModel : Flags -> ( Model, Cmd Msg )
initialModel flags =
    ( { data = flags.data
      , componentParams = flags.componentParams
      , clickCount = 0
      }
    , Cmd.none
    )



-- MODEL


type alias Flags =
    { data : { id : Int, title : String }
    , componentParams : { variant : String }
    }


type alias Model =
    { data : { id : Int, title : String }
    , componentParams : { variant : String }
    , clickCount : Int
    }


type Msg
    = ClickedButton
    | ComponentRefreshed Flags



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ComponentRefreshed newModel ->
            ( { model | data = newModel.data, componentParams = newModel.componentParams }, Cmd.none )

        ClickedButton ->
            ( { model | clickCount = model.clickCount + 1 }, onButtonClick model.data.id )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    componentRefresh ComponentRefreshed



-- VIEW


view : Model -> Html Msg
view model =
    let
        -- The ID could be used to filter events by target in the main application
        buttonId =
            String.concat [ "button-", String.fromInt model.data.id ]

        buttonTitle =
            String.join " " [ "Hello", model.data.title, String.fromInt model.clickCount ]
    in
    button
        (id buttonId
            :: type_ "button"
            :: onClick ClickedButton
            :: variantStyling model.componentParams.variant
        )
        [ text buttonTitle ]


{-| Depending on the `variant` which is passed as `componentParams` value
we use a different styling for the button.
-}
variantStyling : String -> List (Html.Attribute Msg)
variantStyling variant =
    case variant of
        "variant-1" ->
            [ style "background-color" "black", style "color" "lightgray" ]

        _ ->
            [ style "background-color" "red", style "color" "white" ]
