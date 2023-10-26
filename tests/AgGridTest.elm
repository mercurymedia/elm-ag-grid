module AgGridTest exposing (suite)

import AgGrid exposing (Aggregation(..), PinningType(..), Sorting(..))
import Expect
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
        ]
