module AgGridTest exposing (suite)

import AgGrid exposing (Aggregation(..), PinningType(..), Sorting(..), defaultGridConfig)
import Expect
import Html.Attributes exposing (default)
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
                            { defaultColumn
                                | settings =
                                    { defaultSettings
                                        | aggFunc = AgGrid.AvgAggregation
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
                    AgGrid.applyColumnState config [ defaultColumn ]
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
                        [ { defaultColumn | field = "foo" }
                        , { defaultColumn | field = "bar" }
                        , { defaultColumn | field = "bazz" }
                        ]
                        |> Expect.equal
                            [ { defaultColumn | field = "bazz" }
                            , { defaultColumn | field = "foo" }
                            , { defaultColumn | field = "bar" }
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
                        [ { defaultColumn | field = "foo" }
                        , { defaultColumn | field = "bazz" }
                        , { defaultColumn | field = "bar" }
                        ]
                        |> Expect.equal
                            [ { defaultColumn | field = "foo" }
                            , { defaultColumn | field = "bar" }
                            , { defaultColumn | field = "bazz" }
                            ]
            ]
        ]
