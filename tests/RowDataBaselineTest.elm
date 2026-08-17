module RowDataBaselineTest exposing (suite)

{-| Pins the exact `rowData` attribute that `AgGrid.grid` writes with the default
`rowDataColumns = AllColumns`.

This module deliberately uses nothing but the API that already existed in 34.0.1, so
it compiles unchanged against that version. Running it against both is how the
introduction of `RowDataColumns` was verified to leave the default output
byte-identical.

-}

import AgGrid
import Dict
import Html.Attributes
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector


type alias Row =
    { id : Int
    , name : String
    , amount : Float
    , note : Maybe String
    }


defaultSettings : AgGrid.ColumnSettings
defaultSettings =
    AgGrid.defaultSettings


defaultGridConfig : AgGrid.GridConfig Row
defaultGridConfig =
    AgGrid.defaultGridConfig


rows : List Row
rows =
    [ { id = 1, name = "Alpha", amount = 1.5, note = Just "first" }
    , { id = 2, name = "Beta", amount = -0.25, note = Nothing }
    ]


columns : List (AgGrid.Column Row)
columns =
    [ AgGrid.Column
        { field = "id"
        , renderer = AgGrid.IntRenderer .id
        , headerName = "Id"
        , settings = defaultSettings
        }
    , AgGrid.ColumnGroup
        { headerName = "Details"
        , children =
            [ AgGrid.Column
                { field = "name"
                , renderer = AgGrid.StringRenderer .name
                , headerName = "Name"
                , settings = defaultSettings
                }
            , AgGrid.Column
                { field = "note"
                , renderer = AgGrid.MaybeStringRenderer .note
                , headerName = "Note"

                -- Hidden, grouped and filtered columns are all encoded under the
                -- default configuration.
                , settings = { defaultSettings | hide = True }
                }
            ]
        }
    , AgGrid.Column
        { field = "amount"
        , renderer = AgGrid.FloatRenderer .amount
        , headerName = "Amount"
        , settings = { defaultSettings | sort = AgGrid.SortAscending }
        }
    , AgGrid.Column
        { field = "spacer"
        , renderer = AgGrid.NoRenderer
        , headerName = ""
        , settings = defaultSettings
        }
    ]


gridConfig : AgGrid.GridConfig Row
gridConfig =
    { defaultGridConfig
        | columnStates =
            [ { aggFunc = Nothing
              , colId = "amount"
              , flex = Nothing
              , hide = Just True
              , pinned = Nothing
              , pivot = Nothing
              , pivotIndex = Nothing
              , rowGroup = Just True
              , rowGroupIndex = Just 0
              , sort = Nothing
              , sortIndex = Nothing
              , width = 120
              }
            ]
        , filterStates = Dict.fromList [ ( "name", AgGrid.SetFilterState { values = [ "Alpha" ] } ) ]
        , isRowSelectable = \row -> row.id == 1
        , rowId = Just (.id >> String.fromInt)
    }


expectedRowData : String
expectedRowData =
    String.concat
        [ "["
        , "{\"rowCallbackValues\":{\"isRowSelectable\":true,\"rowId\":\"1\"}"
        , ",\"id\":1,\"name\":\"Alpha\",\"note\":\"first\",\"amount\":1.5,\"spacer\":null}"
        , ","
        , "{\"rowCallbackValues\":{\"isRowSelectable\":false,\"rowId\":\"2\"}"
        , ",\"id\":2,\"name\":\"Beta\",\"note\":null,\"amount\":-0.25,\"spacer\":null}"
        , "]"
        ]


suite : Test
suite =
    describe "rowData with the default configuration"
        [ test "encodes every column of every row, groups flattened in place" <|
            \_ ->
                AgGrid.grid gridConfig [] columns rows
                    |> Query.fromHtml
                    |> Query.has
                        [ Selector.attribute (Html.Attributes.attribute "rowData" expectedRowData) ]
        ]
