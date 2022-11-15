port module Main exposing (main)

import AgGrid exposing (Renderer(..))
import Browser
import Dict exposing (Dict)
import Html exposing (Html, div, input)
import Html.Attributes exposing (placeholder, style, value)
import Html.Events exposing (onInput)
import Json.Decode
import Json.Decode.Pipeline as DecodePipeline
import Json.Encode
import Result exposing (Result)


port buttonClicked : (Int -> msg) -> Sub msg


port setItem : ( String, Json.Encode.Value ) -> Cmd msg


port requestItem : String -> Cmd msg


port receivedItem : (( String, Json.Encode.Value ) -> msg) -> Sub msg



-- INIT


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


init : () -> ( Model, Cmd Msg )
init _ =
    ( initialModel, requestItem gridColumnStorageKey )


initialModel : Model
initialModel =
    let
        -- List of the same two elements repeated several times
        -- to create a representable long lists for the AgGrid table.
        products =
            [ { amountLeft = Nothing
              , category = Fruit
              , description = Nothing
              , detailsUrl = "#/apple"
              , favorite = False
              , id = 1
              , offerUntil = "01/01/2022"
              , price = 3.2
              , title = "Apple"
              }
            , { amountLeft = Just 15
              , category = Vegetable
              , description = Just "It's a pickle"
              , favorite = True
              , id = 2
              , offerUntil = "31/12/2022"
              , price = 2.5
              , title = "Cucumber"
              , detailsUrl = "#/cucumber"
              }
            ]
                |> List.repeat 150
                |> List.concat
                -- Provide unique index to simplify table updates
                |> List.indexedMap (\index product -> ( index, { product | id = index } ))
                |> Dict.fromList
    in
    { searchInput = ""
    , products = products
    , variant = "variant-1"
    , initialColumnStates = Nothing
    }



-- MODEL


type alias Model =
    { searchInput : String
    , products : Dict Int Product
    , variant : String
    , initialColumnStates : Maybe (List AgGrid.ColumnState)
    }


type Msg
    = NoOp
    | UpdateSearchInput String
    | UpdateProduct (Result Json.Decode.Error Product)
    | ClickedCellButton Int
    | ColumnStateChanged (AgGrid.StateChange (List AgGrid.ColumnState))
    | ReceivedColumnStates (Result Json.Decode.Error (List AgGrid.ColumnState))


type Category
    = Vegetable
    | Fruit


type alias Product =
    { amountLeft : Maybe Int
    , category : Category
    , description : Maybe String
    , detailsUrl : String
    , favorite : Bool
    , id : Int
    , offerUntil : String
    , price : Float
    , title : String
    }



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        UpdateSearchInput newSearchValue ->
            ( { model | searchInput = newSearchValue }, Cmd.none )

        UpdateProduct (Ok updatedProduct) ->
            let
                updatedProducts =
                    Dict.update updatedProduct.id (always (Just updatedProduct)) model.products
            in
            ( { model | products = updatedProducts }, Cmd.none )

        UpdateProduct (Err err) ->
            ( model, Cmd.none )

        ClickedCellButton id ->
            let
                updatedVariant =
                    case model.variant of
                        "variant-1" ->
                            "variant-2"

                        _ ->
                            "variant-1"
            in
            ( { model | variant = updatedVariant }, Cmd.none )

        ColumnStateChanged {states} ->
            ({model | initialColumnStates = Just states}, setItem ( gridColumnStorageKey, AgGrid.columnStatesEncoder states ) )

        ReceivedColumnStates (states) ->
            ( { model | initialColumnStates = Result.toMaybe states }, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    let
        gridConfig =
            AgGrid.defaultGridConfig
                |> (\config ->
                        { config
                            | sideBar = AgGrid.BothSidebars
                            , pagination = True
                            , quickFilterText = model.searchInput
                            , cacheQuickFilter = True
                            , themeClasses = Just "ag-theme-balham ag-basic"
                            , columnStates = Maybe.withDefault [] model.initialColumnStates
                        }
                   )

        defaultSettings =
            AgGrid.defaultSettings
                |> (\settings -> { settings | editable = True })

        columns =
            [ { field = "id"
              , renderer = IntRenderer .id
              , headerName = "Id"
              , settings = { defaultSettings | hide = True }
              }
            , { field = "title"
              , renderer = StringRenderer .title
              , headerName = "Product"
              , settings = { defaultSettings | editable = False, pinned = AgGrid.PinnedToLeft }
              }
            , { field = "details"
              , renderer = AppRenderer { componentName = "linkRenderer", componentParams = Nothing } encodeDetails
              , headerName = "Details"
              , settings = { defaultSettings | editable = False }
              }
            , { field = "detailsUrl"
              , renderer = StringRenderer .detailsUrl
              , headerName = ""
              , settings = { defaultSettings | hide = True }
              }
            , { field = "category"
              , renderer = SelectionRenderer (.category >> categoryToString) (List.map categoryToString [ Fruit, Vegetable ])
              , headerName = "Category"
              , settings = defaultSettings
              }
            , { field = "description"
              , renderer = MaybeStringRenderer .description
              , headerName = "Description"
              , settings = defaultSettings
              }
            , { field = "favorite"
              , renderer = BoolRenderer .favorite
              , headerName = "Favorite"
              , settings = defaultSettings
              }
            , { field = "offer-until"
              , renderer = StringRenderer .offerUntil
              , headerName = "Offer until"
              , settings = defaultSettings
              }
            , { field = "price"
              , renderer = FloatRenderer .price
              , headerName = "Price"
              , settings = { defaultSettings | filter = AgGrid.NumberFilter }
              }
            , { field = "amount-left"
              , renderer = MaybeIntRenderer .amountLeft
              , headerName = "Amount Left"
              , settings = defaultSettings
              }
            , { field = "table-button-column"
              , renderer = AppRenderer (buttonConfig model) (always "")
              , headerName = ""
              , settings = { defaultSettings | editable = False }
              }
            ]
    in
    div []
        [ input
            [ value model.searchInput
            , onInput UpdateSearchInput
            , placeholder "Search ..."
            , style "margin-bottom" "8px"
            ]
            []
        , AgGrid.grid gridConfig
            [ AgGrid.onCellChanged rowDecoder UpdateProduct
            , AgGrid.onColumnStateChanged ColumnStateChanged

            -- Eventlistener is not attached. Communication happens through ports.
            -- , onCellClicked ClickedCellButton
            ]
            columns
            (Dict.values model.products)
        ]


encodeDetails : Product -> String
encodeDetails product =
    Json.Encode.object
        [ ( "url", Json.Encode.string product.detailsUrl )
        , ( "linkName", Json.Encode.string product.title )
        ]
        |> Json.Encode.encode 0


buttonConfig : Model -> { componentName : String, componentParams : Maybe Json.Encode.Value }
buttonConfig model =
    let
        params =
            Json.Encode.object
                [ ( "variant", Json.Encode.string model.variant )
                ]
    in
    { componentName = "buttonRenderer"
    , componentParams = Just params
    }


{-| Possible event listener for button click events.

Attempts to read the Product Id of from the the clicked element ID that has
a format of `button-123`.

It's probably easiert to just use ports for communication with the components,
as this doesn't require to listen for all click events, filtering them, and
parsing a potential ID from a string.

The port provides more accuracy to only receive a message event when the actual
element was clicked and allows to send information much easier.

-}
onCellClicked : (Int -> Msg) -> Html.Attribute Msg
onCellClicked toMsg =
    let
        parseElementId elementId =
            case String.split "-" elementId of
                _ :: idString :: _ ->
                    String.toInt idString

                _ ->
                    Nothing

        valueDecoder =
            Json.Decode.at [ "target", "id" ] Json.Decode.string
                |> Json.Decode.andThen
                    (\elementId ->
                        case parseElementId elementId of
                            Just id ->
                                Json.Decode.succeed id

                            Nothing ->
                                Json.Decode.fail "invalid value"
                    )
                |> Json.Decode.map toMsg
    in
    Html.Events.on "click" valueDecoder



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ buttonClicked ClickedCellButton
        , receivedItem
            (\( key, value ) ->
                if key == gridColumnStorageKey then
                    value
                        |> Json.Decode.decodeValue AgGrid.columnStatesDecoder
                        |> ReceivedColumnStates

                else
                    NoOp
            )
        ]



-- HELPER


categoryToString : Category -> String
categoryToString category =
    case category of
        Fruit ->
            "Fruit"

        Vegetable ->
            "Vegetable"


decodeCategory : String -> Json.Decode.Decoder Category
decodeCategory categoryString =
    case categoryString of
        "Fruit" ->
            Json.Decode.succeed Fruit

        "Vegetable" ->
            Json.Decode.succeed Vegetable

        _ ->
            Json.Decode.fail "Failed decoding category"


gridColumnStorageKey : String
gridColumnStorageKey =
    "elm-ag-grid-columns"


rowDecoder : Json.Decode.Decoder Product
rowDecoder =
    Json.Decode.succeed Product
        |> DecodePipeline.required "amount-left" (Json.Decode.nullable Json.Decode.int)
        |> DecodePipeline.required "category" (Json.Decode.string |> Json.Decode.andThen decodeCategory)
        |> DecodePipeline.required "description" (Json.Decode.nullable Json.Decode.string)
        |> DecodePipeline.required "detailsUrl" Json.Decode.string
        |> DecodePipeline.required "favorite" Json.Decode.bool
        |> DecodePipeline.required "id" Json.Decode.int
        |> DecodePipeline.required "offer-until" Json.Decode.string
        |> DecodePipeline.required "price"
            (Json.Decode.oneOf
                [ Json.Decode.float
                , Json.Decode.map (String.toFloat >> Maybe.withDefault 0) Json.Decode.string
                ]
            )
        |> DecodePipeline.required "title" Json.Decode.string
