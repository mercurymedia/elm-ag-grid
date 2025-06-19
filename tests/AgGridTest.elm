module AgGridTest exposing (suite)

import AgGrid exposing (Aggregation(..), PinningType(..), Sorting(..), defaultGridConfig)
import Dict
import Expect
import Json.Decode
import Test exposing (..)


suite : Test
suite =
    describe "AgGrid"
        [ describe "aggregationToString/toAggregation roundtrip"
            [ test "should stringify and parse the Aggregations properly" <|
                \_ ->
                    let
                        input =
                            [ AvgAggregation
                            , CountAggregation
                            , CustomAggregation "foo"
                            , FirstAggregation
                            , LastAggregation
                            , MaxAggregation
                            , MinAggregation
                            , NoAggregation
                            , SumAggregation
                            ]

                        result =
                            List.map
                                (\aggregation ->
                                    aggregation
                                        |> AgGrid.aggregationToString
                                        |> AgGrid.toAggregation
                                )
                                input
                    in
                    Expect.equalLists input result
            ]
        , describe "pinningTypeToString/toPinningType roundtrip"
            [ test "should stringify and parse the PinningType properly" <|
                \_ ->
                    let
                        input =
                            [ PinnedToLeft
                            , PinnedToRight
                            , Unpinned
                            ]

                        result =
                            List.map
                                (\aggregation ->
                                    aggregation
                                        |> AgGrid.pinningTypeToString
                                        |> AgGrid.toPinningType
                                )
                                input
                    in
                    Expect.equalLists input result
            ]
        , describe "sortingToString/toSorting roundtrip"
            [ test "should stringify and parse the Sorting properly" <|
                \_ ->
                    let
                        input =
                            [ SortAscending
                            , SortDescending
                            , NoSorting
                            ]

                        result =
                            List.map
                                (\aggregation ->
                                    aggregation
                                        |> AgGrid.sortingToString
                                        |> AgGrid.toSorting
                                )
                                input
                    in
                    Expect.equalLists input result
            ]
        , let
            defaultSettings =
                AgGrid.defaultSettings
                    |> (\settings ->
                            { settings
                                | aggFunc = AgGrid.NoAggregation
                                , allowedAggFuncs = Just [ AgGrid.SumAggregation, AgGrid.AvgAggregation ]
                                , defaultAggFunc = AgGrid.SumAggregation
                                , flex = Nothing
                                , hide = False
                                , pinned = AgGrid.Unpinned
                                , pivot = False
                                , pivotIndex = Nothing
                                , rowGroup = False
                                , rowGroupIndex = Nothing
                                , sort = AgGrid.NoSorting
                                , sortIndex = Nothing
                                , width = Just 100
                            }
                       )

            defaultColumn =
                { field = "test"
                , renderer = AgGrid.StringRenderer .foo
                , headerName = "Test"
                , settings = defaultSettings
                }

            defaultColumnState =
                { aggFunc = Nothing
                , colId = "test"
                , flex = Nothing
                , hide = Nothing
                , pinned = Nothing
                , pivot = Nothing
                , pivotIndex = Nothing
                , rowGroup = Nothing
                , rowGroupIndex = Nothing
                , sort = Nothing
                , sortIndex = Nothing
                , width = 100
                }
          in
          describe "applyColumnState"
            [ test "should update ColumnDef according to the column state" <|
                \_ ->
                    let
                        config =
                            { defaultGridConfig
                                | columnStates =
                                    [ { aggFunc = Just "avg"
                                      , colId = "test"
                                      , flex = Just 5
                                      , hide = Just True
                                      , pinned = Just "left"
                                      , pivot = Just True
                                      , pivotIndex = Just 1
                                      , rowGroup = Just True
                                      , rowGroupIndex = Just 2
                                      , sort = Just "asc"
                                      , sortIndex = Just 3
                                      , width = 150
                                      }
                                    ]
                            }

                        expected =
                            AgGrid.Column
                                { defaultColumn
                                    | settings =
                                        { defaultSettings
                                            | aggFunc = AgGrid.AvgAggregation
                                            , allowedAggFuncs = Just [ AgGrid.SumAggregation, AgGrid.AvgAggregation ]
                                            , defaultAggFunc = AgGrid.SumAggregation
                                            , flex = Just 5
                                            , hide = True
                                            , pinned = AgGrid.PinnedToLeft
                                            , pivot = True
                                            , pivotIndex = Just 1
                                            , rowGroup = True
                                            , rowGroupIndex = Just 2
                                            , sort = AgGrid.SortAscending
                                            , sortIndex = Just 3
                                            , width = Just 150
                                        }
                                }
                    in
                    AgGrid.applyColumnState config [ AgGrid.Column defaultColumn ]
                        |> Expect.equal [ expected ]
            , test "should apply the order from the column state" <|
                \_ ->
                    let
                        config =
                            { defaultGridConfig
                                | columnStates =
                                    [ { defaultColumnState | colId = "bazz" }
                                    , { defaultColumnState | colId = "foo" }
                                    , { defaultColumnState | colId = "bar" }
                                    ]
                            }
                    in
                    AgGrid.applyColumnState config
                        [ AgGrid.Column { defaultColumn | field = "foo" }
                        , AgGrid.Column { defaultColumn | field = "bar" }
                        , AgGrid.Column { defaultColumn | field = "bazz" }
                        ]
                        |> Expect.equal
                            [ AgGrid.Column { defaultColumn | field = "bazz" }
                            , AgGrid.Column { defaultColumn | field = "foo" }
                            , AgGrid.Column { defaultColumn | field = "bar" }
                            ]
            , test "should append columns that are not in the state to the end" <|
                \_ ->
                    let
                        config =
                            { defaultGridConfig
                                | columnStates =
                                    [ { defaultColumnState | colId = "foo" }
                                    , { defaultColumnState | colId = "bar" }
                                    ]
                            }
                    in
                    AgGrid.applyColumnState config
                        [ AgGrid.Column { defaultColumn | field = "foo" }
                        , AgGrid.Column { defaultColumn | field = "bazz" }
                        , AgGrid.Column { defaultColumn | field = "bar" }
                        ]
                        |> Expect.equal
                            [ AgGrid.Column { defaultColumn | field = "foo" }
                            , AgGrid.Column { defaultColumn | field = "bar" }
                            , AgGrid.Column { defaultColumn | field = "bazz" }
                            ]
            ]
        , describe "filterState roundtrip"
            [ test "should stringify and parse TextFilterState properly" <|
                \_ ->
                    let
                        input =
                            [ ( "text"
                              , AgGrid.TextFilterState
                                    { filter = Nothing
                                    , type_ = Just "contains"
                                    , operator = Just "AND"
                                    , conditions =
                                        [ { type_ = "contains", filter = "test" }
                                        , { type_ = "startsWith", filter = "foo" }
                                        ]
                                    }
                              )
                            ]

                        result =
                            AgGrid.filterStatesEncoder (input |> Dict.fromList)
                    in
                    Expect.equal input
                        (Json.Decode.decodeValue AgGrid.filterStatesDecoder result |> Result.withDefault Dict.empty |> Dict.toList)
            , test "should stringify and parse NumberFilterState properly" <|
                \_ ->
                    let
                        input =
                            [ ( "number"
                              , AgGrid.NumberFilterState
                                    { filter = Just 42.5
                                    , type_ = Just "greaterThan"
                                    , operator = Just "OR"
                                    , conditions =
                                        [ { type_ = "equals", filter = 10.0 }
                                        , { type_ = "lessThan", filter = 100.0 }
                                        ]
                                    }
                              )
                            ]

                        result =
                            AgGrid.filterStatesEncoder (input |> Dict.fromList)
                    in
                    Expect.equal input
                        (Json.Decode.decodeValue AgGrid.filterStatesDecoder result |> Result.withDefault Dict.empty |> Dict.toList)
            , test "should stringify and parse DateFilterState properly" <|
                \_ ->
                    let
                        input =
                            [ ( "date"
                              , AgGrid.DateFilterState
                                    { dateFrom = Just "2023-01-01"
                                    , dateTo = Just "2023-12-31"
                                    , type_ = Just "inRange"
                                    , operator = Just "AND"
                                    , conditions =
                                        [ { type_ = "equals", dateFrom = Just "2023-06-01", dateTo = Just "2023-06-01" }
                                        , { type_ = "greaterThan", dateFrom = Just "2023-01-01", dateTo = Just "2023-01-01" }
                                        ]
                                    }
                              )
                            ]

                        result =
                            AgGrid.filterStatesEncoder (input |> Dict.fromList)
                    in
                    Expect.equal input
                        (Json.Decode.decodeValue AgGrid.filterStatesDecoder result |> Result.withDefault Dict.empty |> Dict.toList)
            , test "should stringify and parse SetFilterState properly" <|
                \_ ->
                    let
                        input =
                            [ ( "set"
                              , AgGrid.SetFilterState
                                    { values = [ "option1", "option2", "option3" ] }
                              )
                            ]

                        result =
                            AgGrid.filterStatesEncoder (input |> Dict.fromList)
                    in
                    Expect.equal input
                        (Json.Decode.decodeValue AgGrid.filterStatesDecoder result |> Result.withDefault Dict.empty |> Dict.toList)
            ]
        ]
