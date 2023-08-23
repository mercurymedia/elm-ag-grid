module Aggregation exposing (Model, Msg, init, subscriptions, update, view)

import AgGrid exposing (Renderer(..), defaultGridConfig, defaultSettings)
import AgGrid.ContextMenu as AgGridContextMenu exposing (defaultActionAttributes)
import AgGrid.Expression as Expression exposing (Eval(..))
import Css
import Dict exposing (Dict)
import Html.Styled exposing (Html, a, div, h3, node, span, text)
import Html.Styled.Attributes exposing (css, href, target)
import Json.Decode as Decode
import Json.Decode.Pipeline as DecodePipeline



-- INIT


init : ( Model, Cmd Msg )
init =
    ( initialModel, Cmd.none )


initialModel : Model
initialModel =
    { costs =
        [ { id = 1, de = { price = Just "472.08", volume = Just 8356, discount = Just 0.19 }, us = { price = Just "8293.27", volume = Just 6299, discount = Just 0.23 } }
        , { id = 2, de = { price = Just "5872.03", volume = Just 7353, discount = Just 0.06 }, us = { price = Just "3403.07", volume = Just 9578, discount = Nothing } }
        , { id = 3, de = { price = Just "214.27", volume = Just 7077, discount = Just 0.2 }, us = { price = Just "7805.74", volume = Just 4274, discount = Just 0.19 } }
        , { id = 4, de = { price = Just "6757.93", volume = Just 4279, discount = Just 0.04 }, us = { price = Nothing, volume = Just 6469, discount = Just 0.04 } }
        , { id = 5, de = { price = Just "1265.69", volume = Just 584, discount = Just 0.088 }, us = { price = Just "6045.89", volume = Just 1262, discount = Just 0.03 } }
        , { id = 6, de = { price = Just "7279.14", volume = Just 5661, discount = Just 0.29 }, us = { price = Just "5359.51", volume = Just 5339, discount = Just 0.11 } }
        , { id = 7, de = { price = Just "2225.44", volume = Just 7670, discount = Just 0.11 }, us = { price = Just "1482.66", volume = Just 3458, discount = Just 0.16 } }
        , { id = 8, de = { price = Just "4824.31", volume = Just 5740, discount = Just 0.22 }, us = { price = Just "2139.21", volume = Just 1022, discount = Just 0.01 } }
        , { id = 9, de = { price = Just "2467.24", volume = Just 6091, discount = Just 0.24 }, us = { price = Just "2491.70", volume = Just 3851, discount = Just 0.11 } }
        , { id = 10, de = { price = Just "8091.13", volume = Just 7634, discount = Just 0.03 }, us = { price = Just "4861.57", volume = Just 1581, discount = Just 0.04 } }
        , { id = 11, de = { price = Just "1474.93", volume = Just 6852, discount = Just 0.06 }, us = { price = Just "2848.18", volume = Just 7808, discount = Nothing } }
        , { id = 12, de = { price = Just "9994.35", volume = Just 9753, discount = Just 0.08 }, us = { price = Just "9.36", volume = Just 2924, discount = Just 0.28 } }
        , { id = 13, de = { price = Just "4105.67", volume = Just 9114, discount = Just 0.15 }, us = { price = Just "988.90", volume = Just 9658, discount = Just 0.13 } }
        , { id = 14, de = { price = Just "6752.43", volume = Just 3745, discount = Just 0.29 }, us = { price = Just "1249.92", volume = Just 4170, discount = Just 0.3 } }
        , { id = 15, de = { price = Just "7044.20", volume = Just 8854, discount = Just 0.11 }, us = { price = Just "1588.78", volume = Just 9120, discount = Just 0.13 } }
        , { id = 16, de = { price = Just "3703.50", volume = Just 5617, discount = Just 0.19 }, us = { price = Just "274.98", volume = Just 6248, discount = Just 0.27 } }
        , { id = 17, de = { price = Just "4086.45", volume = Just 4555, discount = Nothing }, us = { price = Just "1695.38", volume = Just 6186, discount = Just 0.18 } }
        , { id = 18, de = { price = Just "4747.25", volume = Just 1672, discount = Just 0.25 }, us = { price = Nothing, volume = Just 7377, discount = Just 0.04 } }
        , { id = 19, de = { price = Just "1029.52", volume = Just 5891, discount = Just 0.08 }, us = { price = Just "2674.76", volume = Just 511, discount = Just 0.16 } }
        , { id = 20, de = { price = Just "119.46", volume = Just 3277, discount = Just 0.2 }, us = { price = Just "9362.26", volume = Just 5652, discount = Just 0.15 } }
        , { id = 21, de = { price = Just "3773.08", volume = Just 8005, discount = Just 0.11 }, us = { price = Just "4372.26", volume = Just 2024, discount = Just 0.06 } }
        , { id = 22, de = { price = Just "7597.33", volume = Just 1116, discount = Just 0.04 }, us = { price = Just "7447.73", volume = Just 7842, discount = Just 0.09 } }
        , { id = 23, de = { price = Just "2444.71", volume = Just 1827, discount = Just 0.24 }, us = { price = Just "2192.61", volume = Just 1370, discount = Just 0.17 } }
        , { id = 24, de = { price = Just "9336.34", volume = Just 1985, discount = Nothing }, us = { price = Just "8758.89", volume = Just 5997, discount = Just 0.15 } }
        , { id = 25, de = { price = Just "7104.82", volume = Just 4838, discount = Nothing }, us = { price = Just "1113.05", volume = Just 7803, discount = Just 0.24 } }
        ]
            |> List.map (\item -> ( item.id, item ))
            |> Dict.fromList
    , counter = 0
    }



-- MODEL


type alias Model =
    { costs : Dict Int LineItem
    , counter : Int
    }


type alias LineItem =
    { id : Int
    , de : Cost
    , us : Cost
    }


type alias Cost =
    { price : Maybe String
    , volume : Maybe Int
    , discount : Maybe Float
    }


type Msg
    = CellChanged (Result Decode.Error LineItem)
    | ContextMenuAction ( Result Decode.Error Int, String )



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        CellChanged (Err err) ->
            ( model, Cmd.none )

        CellChanged (Ok change) ->
            ( { model | costs = Dict.insert change.id change model.costs }, Cmd.none )

        ContextMenuAction ( result, action ) ->
            case ( result, action ) of
                ( Ok _, "incrementCounter" ) ->
                    ( { model | counter = model.counter + 1 }, Cmd.none )

                _ ->
                    ( model, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    div [ css [ Css.width (Css.pct 100), Css.margin2 (Css.rem 0) (Css.rem 1) ] ]
        [ div [ css [ Css.margin2 (Css.rem 1) (Css.px 0), Css.displayFlex, Css.alignItems Css.center ] ]
            [ span [ css [ Css.fontSize (Css.rem 1.8), Css.marginRight (Css.px 5) ] ] [ text "Aggregations & Formatting" ]
            , a [ href "https://github.com/mercurymedia/elm-ag-grid/blob/main/examples/src/Aggregation.elm", target "_blank" ] [ text "[source]" ]
            ]
        , div [ css [] ]
            [ div [] [ text "Formatting values as currencies, decimals, or percentages utilizing the predefined CurrencyRenderer/DecimalRenderer/PercentRenderer and aggregating those values in the footer." ]
            , div [ css [ Css.marginTop (Css.rem 1) ] ] [ text "This formatting can be customized by overwriting the valueFormatter expression on the column settings." ]
            ]
        , viewGrid model
        , div []
            [ h3 [] [ text ("You increased the counter from the context menu " ++ String.fromInt model.counter ++ " times!") ] ]
        ]


viewGrid : Model -> Html Msg
viewGrid model =
    let
        gridConfig =
            { defaultGridConfig
                | themeClasses = Just "ag-theme-balham ag-basic"
                , groupIncludeTotalFooter = True
                , size = "65vh"
                , contextMenu =
                    Just
                        [ AgGridContextMenu.autoSizeAllContextAction
                        , AgGridContextMenu.contextAction
                            { defaultActionAttributes
                                | name = "Edit"
                                , subMenu =
                                    [ AgGridContextMenu.ChildContextAction AgGridContextMenu.copyContextAction
                                    , AgGridContextMenu.ChildContextAction AgGridContextMenu.contextSeparator
                                    , AgGridContextMenu.ChildContextAction AgGridContextMenu.pasteContextAction
                                    ]
                            }
                        , AgGridContextMenu.contextAction
                            { defaultActionAttributes
                                | name = "Increase counter"
                                , actionName = Just "incrementCounter"
                                , disabled = Expression.Expr (Expression.lte (Expression.value "id") (Expression.int 10))
                            }
                        ]
            }

        gridSettings =
            { defaultSettings | editable = Expression.Const True }

        columns =
            [ { field = "id"
              , renderer = IntRenderer .id
              , headerName = "ID"
              , settings = gridSettings
              }
            , { field = "priceDE"
              , renderer = CurrencyRenderer { currency = "EUR", countryCode = "de" } (.de >> .price)
              , headerName = "Price DE"
              , settings = { gridSettings | aggFunc = AgGrid.MinAggregation }
              }
            , { field = "volumeDE"
              , renderer = DecimalRenderer { countryCode = "de", decimalPlaces = 0 } (.de >> .volume >> Maybe.map String.fromInt)
              , headerName = "Volume DE"
              , settings = { gridSettings | aggFunc = AgGrid.SumAggregation }
              }
            , { field = "discountDE"
              , renderer = PercentRenderer { countryCode = "de", decimalPlaces = 2 } (.de >> .discount >> Maybe.map (toPct >> String.fromFloat))
              , headerName = "Discount DE"
              , settings = { gridSettings | aggFunc = AgGrid.AvgAggregation }
              }
            , { field = "priceUS"
              , renderer = CurrencyRenderer { countryCode = "us", currency = "USD" } (.us >> .price)
              , headerName = "Price US"
              , settings = { gridSettings | aggFunc = AgGrid.AvgAggregation }
              }
            , { field = "volumeUS"
              , renderer = DecimalRenderer { countryCode = "us", decimalPlaces = 0 } (.us >> .volume >> Maybe.map String.fromInt)
              , headerName = "Volume US"
              , settings = { gridSettings | aggFunc = AgGrid.AvgAggregation }
              }
            , { field = "discountUS"
              , renderer = PercentRenderer { countryCode = "us", decimalPlaces = 2 } (.us >> .discount >> Maybe.map (toPct >> String.fromFloat))
              , headerName = "Discount US"
              , settings = { gridSettings | aggFunc = AgGrid.AvgAggregation }
              }
            , { field = "minAndMax"
              , renderer = MaybeStringRenderer (.us >> .discount >> Maybe.map (toPct >> String.fromFloat))
              , headerName = "Min & Max (Custom aggregation)"
              , settings = { gridSettings | aggFunc = AgGrid.CustomAggregation "Min&Max" }
              }
            ]
    in
    node "aggregation-grid"
        [ css [ Css.display Css.block, Css.margin2 (Css.rem 1) (Css.px 0) ] ]
        [ AgGrid.grid gridConfig
            [ AgGrid.onCellChanged changeDecoder CellChanged
            , AgGrid.onContextMenu idDecoder ContextMenuAction
            ]
            columns
            (Dict.values model.costs)
            |> Html.Styled.fromUnstyled
        ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- DECODER


changeDecoder : Decode.Decoder LineItem
changeDecoder =
    let
        costDecoder priceField volumeField discountField =
            Decode.succeed Cost
                |> DecodePipeline.optional priceField (Decode.nullable Decode.string) Nothing
                |> DecodePipeline.optional volumeField (Decode.string |> Decode.map String.toInt) Nothing
                |> DecodePipeline.optional discountField (Decode.string |> Decode.map (String.toFloat >> Maybe.map toDecimal)) Nothing
    in
    Decode.succeed LineItem
        |> DecodePipeline.required "id" Decode.int
        |> DecodePipeline.custom (costDecoder "priceDE" "volumeDE" "discountDE")
        |> DecodePipeline.custom (costDecoder "priceUS" "volumeUS" "discountUS")


idDecoder : Decode.Decoder Int
idDecoder =
    Decode.field "id" Decode.int


toPct : Float -> Float
toPct decimal =
    decimal * 100


toDecimal : Float -> Float
toDecimal pct =
    pct / 100
