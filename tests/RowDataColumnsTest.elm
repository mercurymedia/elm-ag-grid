module RowDataColumnsTest exposing (suite)

{-| Which fields end up in the `rowData` attribute under
`rowDataColumns = UsedColumns`.
-}

import AgGrid exposing (RowDataColumns(..))
import AgGrid.ContextMenu as ContextMenu
import AgGrid.Expression as Expression exposing (Eval(..))
import Dict
import Expect
import Html
import Html.Attributes
import Json.Encode
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector


type alias Row =
    { id : Int
    , name : String
    , status : String
    , note : String
    }


row : Row
row =
    { id = 1, name = "Alpha", status = "active", note = "first" }



-- The encoded form of every field of `row`, to assemble expectations from.


idField : String
idField =
    "\"id\":1"


nameField : String
nameField =
    "\"name\":\"Alpha\""


statusField : String
statusField =
    "\"status\":\"active\""


noteField : String
noteField =
    "\"note\":\"first\""


defaultSettings : AgGrid.ColumnSettings
defaultSettings =
    AgGrid.defaultSettings


hiddenSettings : AgGrid.ColumnSettings
hiddenSettings =
    { defaultSettings | hide = True }


defaultGridConfig : AgGrid.GridConfig Row
defaultGridConfig =
    AgGrid.defaultGridConfig


{-| `id` and `name` are displayed, `status` and `note` are hidden.
-}
gridConfig : AgGrid.GridConfig Row
gridConfig =
    { defaultGridConfig | rowDataColumns = UsedColumns { alsoEncode = [] } }


column : String -> AgGrid.ColumnSettings -> AgGrid.Column Row
column field settings =
    AgGrid.Column
        { field = field
        , renderer =
            case field of
                "id" ->
                    AgGrid.IntRenderer .id

                "name" ->
                    AgGrid.StringRenderer .name

                "status" ->
                    AgGrid.StringRenderer .status

                "note" ->
                    AgGrid.StringRenderer .note

                unknown ->
                    -- Encodes something no expectation matches, so a mistyped
                    -- field name fails the test instead of quietly picking up
                    -- another column's renderer.
                    AgGrid.StringRenderer (\_ -> "no renderer for " ++ unknown)
        , headerName = field
        , settings = settings
        }


columns : List (AgGrid.Column Row)
columns =
    [ column "id" defaultSettings
    , column "name" defaultSettings
    , column "status" hiddenSettings
    , column "note" hiddenSettings
    ]


columnState : String -> AgGrid.ColumnState
columnState colId =
    { aggFunc = Nothing
    , colId = colId
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


stateWith : String -> (AgGrid.ColumnState -> AgGrid.ColumnState) -> AgGrid.ColumnState
stateWith colId adjust =
    adjust (columnState colId)


{-| A single row holding exactly the given encoded fields.
-}
expectedRowData : List String -> String
expectedRowData fields =
    "[{\"rowCallbackValues\":{\"isRowSelectable\":true,\"rowId\":null}"
        ++ String.concat (List.map (\field -> "," ++ field) fields)
        ++ "}]"


expectFields : List String -> Html.Html () -> Expect.Expectation
expectFields fields html =
    html
        |> Query.fromHtml
        |> Query.has
            [ Selector.attribute (Html.Attributes.attribute "rowData" (expectedRowData fields)) ]


{-| Render the default fixture with an adjusted grid config.
-}
gridWith : (AgGrid.GridConfig Row -> AgGrid.GridConfig Row) -> Html.Html ()
gridWith adjust =
    AgGrid.grid (adjust gridConfig) [] columns [ row ]


{-| Render an adjusted fixture with the default grid config.
-}
gridOf : List (AgGrid.Column Row) -> Html.Html ()
gridOf columnDefs =
    AgGrid.grid gridConfig [] columnDefs [ row ]


{-| Replace the settings of a single column of the default fixture.
-}
withSettings : String -> AgGrid.ColumnSettings -> List (AgGrid.Column Row)
withSettings field settings =
    List.map
        (\existing ->
            case existing of
                AgGrid.Column columnDef ->
                    if columnDef.field == field then
                        column field settings

                    else
                        existing

                AgGrid.ColumnGroup _ ->
                    existing
        )
        columns


readsStatus : Eval Bool
readsStatus =
    Expr (Expression.eq (Expression.value "status") (Expression.string "active"))


suite : Test
suite =
    describe "rowDataColumns = UsedColumns"
        [ describe "column state"
            [ test "drops hidden columns" <|
                \_ ->
                    gridWith identity
                        |> expectFields [ idField, nameField ]
            , test "does not change which column wins when two share a field" <|
                \_ ->
                    -- Json.Encode.object collapses duplicate keys and the last one
                    -- wins. The hidden column here is encoded too, because the
                    -- field is in the keep-set, so the winner stays the same as it
                    -- would be with AllColumns.
                    gridOf
                        [ column "id" defaultSettings
                        , column "name" defaultSettings
                        , AgGrid.Column
                            { field = "name"
                            , renderer = AgGrid.StringRenderer .status
                            , headerName = "name"
                            , settings = hiddenSettings
                            }
                        ]
                        |> expectFields [ idField, "\"name\":\"active\"" ]
            , test "keeps a hidden column that is sorted through its settings" <|
                \_ ->
                    gridOf (withSettings "status" { hiddenSettings | sort = AgGrid.SortAscending })
                        |> expectFields [ idField, nameField, statusField ]
            , test "keeps a hidden column that has a sort index" <|
                \_ ->
                    gridOf (withSettings "status" { hiddenSettings | sortIndex = Just 0 })
                        |> expectFields [ idField, nameField, statusField ]
            , test "keeps a hidden column that is grouped" <|
                \_ ->
                    gridWith
                        (\config ->
                            { config
                                | columnStates =
                                    [ stateWith "status" (\state -> { state | rowGroup = Just True }) ]
                            }
                        )
                        |> expectFields [ idField, nameField, statusField ]
            , test "keeps a hidden column that has a row group index" <|
                \_ ->
                    gridWith
                        (\config ->
                            { config
                                | columnStates =
                                    [ stateWith "status" (\state -> { state | rowGroupIndex = Just 0 }) ]
                            }
                        )
                        |> expectFields [ idField, nameField, statusField ]
            , test "keeps a hidden column that is pivoted" <|
                \_ ->
                    gridOf (withSettings "status" { hiddenSettings | pivot = True })
                        |> expectFields [ idField, nameField, statusField ]
            , test "keeps a hidden column that has a pivot index" <|
                \_ ->
                    gridOf (withSettings "status" { hiddenSettings | pivotIndex = Just 0 })
                        |> expectFields [ idField, nameField, statusField ]
            , test "keeps a hidden column that is aggregated" <|
                \_ ->
                    gridOf (withSettings "status" { hiddenSettings | aggFunc = AgGrid.SumAggregation })
                        |> expectFields [ idField, nameField, statusField ]
            , test "hides a displayed column when the column state hides it" <|
                \_ ->
                    gridWith
                        (\config ->
                            { config
                                | columnStates =
                                    [ stateWith "name" (\state -> { state | hide = Just True }) ]
                            }
                        )
                        |> expectFields [ idField ]
            , test "takes the sorting from the column state rather than from the settings" <|
                \_ ->
                    -- The state has an entry for the column, so its `sort = Nothing`
                    -- wins over the sorting configured on the column itself.
                    AgGrid.grid
                        { gridConfig | columnStates = [ columnState "status" ] }
                        []
                        (withSettings "status" { hiddenSettings | sort = AgGrid.SortAscending })
                        [ row ]
                        |> expectFields [ idField, nameField ]
            , test "falls back to the settings when the column state leaves `hide` undecided" <|
                \_ ->
                    gridWith (\config -> { config | columnStates = [ columnState "status" ] })
                        |> expectFields [ idField, nameField ]
            , describe "the keep-set reads a column state exactly as applyColumnState overlays it"
                -- The keep-set evaluates the overlay rules directly instead of
                -- building the merged ColumnSettings, because the record copy costs
                -- more than the encoding it saves. These cases pin the two in step.
                (let
                    -- `status` starts hidden; `name` starts displayed.
                    case_ name settingsField stateField expected =
                        test name <|
                            \_ ->
                                AgGrid.grid
                                    { gridConfig | columnStates = [ stateField ] }
                                    []
                                    (withSettings "status" settingsField)
                                    [ row ]
                                    |> expectFields expected
                 in
                 [ case_ "state hide=False un-hides a hidden column"
                    hiddenSettings
                    (stateWith "status" (\st -> { st | hide = Just False }))
                    [ idField, nameField, statusField ]
                 , case_ "state hide=Nothing keeps the settings' hide"
                    hiddenSettings
                    (stateWith "status" identity)
                    [ idField, nameField ]
                 , case_ "state rowGroup=False overrides a grouped setting"
                    { hiddenSettings | rowGroup = True }
                    (stateWith "status" (\st -> { st | rowGroup = Just False }))
                    [ idField, nameField ]
                 , case_ "state pivot=False overrides a pivoted setting"
                    { hiddenSettings | pivot = True }
                    (stateWith "status" (\st -> { st | pivot = Just False }))
                    [ idField, nameField ]
                 , case_ "state aggFunc wins over the settings' aggFunc"
                    { hiddenSettings | aggFunc = AgGrid.SumAggregation }
                    (stateWith "status" identity)
                    [ idField, nameField ]
                 , case_ "state aggFunc adds an aggregation the settings lack"
                    hiddenSettings
                    (stateWith "status" (\st -> { st | aggFunc = Just "sum" }))
                    [ idField, nameField, statusField ]
                 , case_ "an unrecognised sort string is not a sort"
                    hiddenSettings
                    (stateWith "status" (\st -> { st | sort = Just "sideways" }))
                    [ idField, nameField ]
                 , case_ "a recognised sort string is a sort"
                    hiddenSettings
                    (stateWith "status" (\st -> { st | sort = Just "desc" }))
                    [ idField, nameField, statusField ]
                 , case_ "state sortIndex wins over the settings' sortIndex"
                    { hiddenSettings | sortIndex = Just 0 }
                    (stateWith "status" identity)
                    [ idField, nameField ]
                 , case_ "state rowGroupIndex wins over the settings' rowGroupIndex"
                    { hiddenSettings | rowGroupIndex = Just 0 }
                    (stateWith "status" identity)
                    [ idField, nameField ]
                 , case_ "state pivotIndex wins over the settings' pivotIndex"
                    { hiddenSettings | pivotIndex = Just 0 }
                    (stateWith "status" identity)
                    [ idField, nameField ]
                 ]
                )
            ]
        , describe "fields requested elsewhere"
            [ test "keeps a hidden column that has a filter state" <|
                \_ ->
                    gridWith
                        (\config ->
                            { config
                                | filterStates =
                                    Dict.fromList
                                        [ ( "status", AgGrid.SetFilterState { values = [ "active" ] } ) ]
                            }
                        )
                        |> expectFields [ idField, nameField, statusField ]
            , test "keeps a hidden column listed in the CSV export column keys" <|
                \_ ->
                    gridWith
                        (\config ->
                            { config
                                | csvExport = Just { fileName = "export.csv", columnKeys = [ "status" ] }
                            }
                        )
                        |> expectFields [ idField, nameField, statusField ]
            , test "keeps a hidden column listed in the Excel export column keys" <|
                \_ ->
                    gridWith
                        (\config ->
                            { config
                                | excelExport = Just { fileName = "export.xlsx", columnKeys = [ "note" ] }
                            }
                        )
                        |> expectFields [ idField, nameField, noteField ]
            , test "keeps a hidden column listed in alsoEncode" <|
                \_ ->
                    gridWith
                        (\config -> { config | rowDataColumns = UsedColumns { alsoEncode = [ "note" ] } })
                        |> expectFields [ idField, nameField, noteField ]
            , test "ignores an alsoEncode entry that names no column" <|
                \_ ->
                    gridWith
                        (\config ->
                            { config | rowDataColumns = UsedColumns { alsoEncode = [ "nowhere" ] } }
                        )
                        |> expectFields [ idField, nameField ]
            , test "drops hidden columns when the export column keys are empty" <|
                \_ ->
                    -- AgGrid falls back to exporting the displayed columns, which
                    -- are encoded anyway.
                    gridWith
                        (\config ->
                            { config
                                | csvExport = Just { fileName = "export.csv", columnKeys = [] }
                                , excelExport = Just { fileName = "export.xlsx", columnKeys = [] }
                            }
                        )
                        |> expectFields [ idField, nameField ]
            ]
        , describe "expressions"
            [ test "keeps a hidden column referenced by a row class rule" <|
                \_ ->
                    gridWith (\config -> { config | rowClassRules = [ ( "is-active", readsStatus ) ] })
                        |> expectFields [ idField, nameField, statusField ]
            , test "keeps a hidden column referenced by the cell class rules of an encoded column" <|
                \_ ->
                    gridOf
                        (withSettings "name"
                            { defaultSettings | cellClassRules = [ ( "is-active", readsStatus ) ] }
                        )
                        |> expectFields [ idField, nameField, statusField ]
            , test "keeps a hidden column referenced by the editable of an encoded column" <|
                \_ ->
                    gridOf (withSettings "name" { defaultSettings | editable = readsStatus })
                        |> expectFields [ idField, nameField, statusField ]
            , test "ignores the cell class rules of a column that is not encoded" <|
                \_ ->
                    -- `note` is hidden, so AgGrid never evaluates its rules.
                    gridOf
                        (withSettings "note"
                            { hiddenSettings | cellClassRules = [ ( "is-active", readsStatus ) ] }
                        )
                        |> expectFields [ idField, nameField ]
            , test "keeps a hidden column referenced by a context menu action" <|
                \_ ->
                    gridWith
                        (\config ->
                            { config
                                | contextMenu =
                                    Just
                                        [ ContextMenu.contextAction
                                            { name = "Cancel"
                                            , checked = Nothing
                                            , actionName = Just "cancel"
                                            , disabled = readsStatus
                                            , icon = Nothing
                                            , cssClasses = []
                                            , subMenu = []
                                            }
                                        ]
                            }
                        )
                        |> expectFields [ idField, nameField, statusField ]
            ]
        , describe "column groups"
            [ test "filters the children of a column group in place" <|
                \_ ->
                    gridOf
                        [ column "id" defaultSettings
                        , AgGrid.ColumnGroup
                            { headerName = "Details"
                            , children =
                                [ column "status" hiddenSettings
                                , column "name" defaultSettings
                                ]
                            }
                        , column "note" hiddenSettings
                        ]
                        |> expectFields [ idField, nameField ]
            , test "reads the column state of a column nested in a column group" <|
                \_ ->
                    -- AgGrid applies the `columnState` attribute to nested columns
                    -- too, so the keep-set has to look them up as well - even
                    -- though `applyColumnState` leaves group children alone when
                    -- it builds the columnDefs.
                    AgGrid.grid
                        { gridConfig
                            | columnStates =
                                [ stateWith "status" (\state -> { state | hide = Just False }) ]
                        }
                        []
                        [ column "id" defaultSettings
                        , AgGrid.ColumnGroup
                            { headerName = "Details"
                            , children =
                                [ column "status" hiddenSettings
                                , column "name" defaultSettings
                                ]
                            }
                        ]
                        [ row ]
                        |> expectFields [ idField, statusField, nameField ]
            , test "keeps a hidden child of a column group that is referenced by a row class rule" <|
                \_ ->
                    AgGrid.grid
                        { gridConfig | rowClassRules = [ ( "is-active", readsStatus ) ] }
                        []
                        [ column "id" defaultSettings
                        , AgGrid.ColumnGroup
                            { headerName = "Details"
                            , children =
                                [ column "status" hiddenSettings
                                , column "name" defaultSettings
                                ]
                            }
                        ]
                        [ row ]
                        |> expectFields [ idField, statusField, nameField ]
            ]
        , describe "configurations that read the whole row"
            [ test "encodes every column when a quick filter is set" <|
                \_ ->
                    gridWith (\config -> { config | quickFilterText = "alpha" })
                        |> expectFields [ idField, nameField, statusField, noteField ]
            , test "encodes every column when a detail renderer is configured" <|
                \_ ->
                    gridWith
                        (\config ->
                            { config
                                | detailRenderer =
                                    Just
                                        { componentName = "detail"
                                        , componentParams = Just (Json.Encode.object [])
                                        , rowHeight = Nothing
                                        }
                            }
                        )
                        |> expectFields [ idField, nameField, statusField, noteField ]
            ]
        , describe "Expression.fieldReferences"
            [ test "returns nothing for a constant" <|
                \_ ->
                    Expression.fieldReferences (Const True)
                        |> Expect.equalLists []
            , test "walks every operator" <|
                \_ ->
                    Expr
                        (Expression.or
                            (Expression.and
                                (Expression.value "a")
                                (Expression.not (Expression.value "b"))
                            )
                            (Expression.includes (Expression.value "c")
                                (Expression.eq (Expression.value "d")
                                    (Expression.gte (Expression.value "e")
                                        (Expression.lte (Expression.value "f") (Expression.value "g"))
                                    )
                                )
                            )
                        )
                        |> Expression.fieldReferences
                        |> Expect.equalLists [ "a", "b", "c", "d", "e", "f", "g" ]
            , test "ignores literals" <|
                \_ ->
                    Expr (Expression.eq (Expression.string "active") (Expression.list [ "a" ]))
                        |> Expression.fieldReferences
                        |> Expect.equalLists []
            ]
        , describe "ContextMenu.fieldReferences"
            [ test "collects references from disabled, cssClasses and sub menus" <|
                \_ ->
                    [ ContextMenu.copyContextAction
                    , ContextMenu.contextAction
                        { name = "Cancel"
                        , checked = Nothing
                        , actionName = Just "cancel"
                        , disabled = Expr (Expression.value "disabledBy")
                        , icon = Nothing
                        , cssClasses = [ ( [ "hidden" ], Expr (Expression.value "hiddenBy") ) ]
                        , subMenu =
                            [ ContextMenu.contextAction
                                { name = "Really cancel"
                                , checked = Nothing
                                , actionName = Just "reallyCancel"
                                , disabled = Expr (Expression.value "subDisabledBy")
                                , icon = Nothing
                                , cssClasses = []
                                , subMenu = []
                                }
                            ]
                        }
                    ]
                        |> ContextMenu.fieldReferences
                        |> Expect.equalLists [ "disabledBy", "hiddenBy", "subDisabledBy" ]
            ]
        ]
