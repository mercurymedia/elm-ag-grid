module AgGrid exposing
    ( Aggregation(..), CellEditor(..), ColumnDef, ColumnSettings, EventType(..), FilterType(..), LockPosition(..), PinningType(..), Renderer(..)
    , RowGroupPanelVisibility(..), RowSelection(..), Sorting(..), StateChange, CsvExportParams, ExcelExportParams
    , GridConfig, grid
    , defaultGridConfig, defaultSettings
    , onCellChanged, onCellDoubleClicked, onSelectionChange, onContextMenu
    , ColumnState, onColumnStateChanged, columnStatesDecoder, columnStatesEncoder, applyColumnState
    , FilterState(..), onFilterStateChanged, filterStatesEncoder, filterStatesDecoder
    , Sidebar, SidebarType(..), SidebarPosition(..), defaultSidebar
    , aggregationToString, pinningTypeToString, sortingToString, toAggregation, toPinningType, toSorting
    )

{-| AgGrid integration for elm.


# Data Types

@docs Aggregation, CellEditor, ColumnDef, ColumnSettings, EventType, FilterType, LockPosition, PinningType, Renderer
@docs RowGroupPanelVisibility, RowSelection, Sorting, StateChange, CsvExportParams, ExcelExportParams


# Grid

@docs GridConfig, grid


# Defaults

@docs defaultGridConfig, defaultSettings


# Events

@docs onCellChanged, onCellDoubleClicked, onSelectionChange, onContextMenu


# ColumnState

@docs ColumnState, onColumnStateChanged, columnStatesDecoder, columnStatesEncoder, applyColumnState


# FilterState

@docs FilterState, onFilterStateChanged, filterStatesEncoder, filterStatesDecoder


# Sidebar

@docs Sidebar, SidebarType, SidebarPosition, defaultSidebar


# Type parser

@docs aggregationToString, pinningTypeToString, sortingToString, toAggregation, toPinningType, toSorting

-}

import AgGrid.ContextMenu as ContextMenu exposing (ContextMenu)
import AgGrid.Expression as Expression exposing (Eval(..))
import AgGrid.ValueFormat as ValueFormat
import Dict
import Html exposing (Html, node)
import Html.Attributes exposing (attribute, class, id, style)
import Html.Events
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as DecodePipeline
import Json.Encode
import Json.Encode.Extra exposing (encodeMaybe)


{-| Variants to aggregate values for a grouped column.
-}
type Aggregation
    = AvgAggregation
    | CountAggregation
    | CustomAggregation String
    | FirstAggregation
    | LastAggregation
    | MaxAggregation
    | MinAggregation
    | NoAggregation
    | SumAggregation


{-| Possible configuration for the CSV export.
-}
type alias CsvExportParams =
    { fileName : String
    , columnKeys : List String
    }


{-| Possible variants of callbacks that can lead to a certain change.
-}
type EventType
    = ColumnMoved
    | ColumnResized
    | ColumnVisible
    | FilterChanged
    | GridColumnsChanged
    | SortChanged
    | ColumnPinned
    | ColumnRowGroupChanged
    | ColumnValueChanged
    | ResetColumns


{-| Possible configuration for the Excel export.
-}
type alias ExcelExportParams =
    { fileName : String
    , columnKeys : List String
    }


{-| Possible filter options for columns.
-}
type FilterType
    = DefaultFilter
    | DateFilter
    | NumberFilter
    | StringFilter
    | SetFilter
    | NoFilter


type FilterButtonType
    = ApplyButton
    | CancelButton
    | ClearButton
    | ResetButton


{-| Lock a column to position to left or right to always have this column displayed in that position.

Or can be configured to not lock in one position and move the column freely.

-}
type LockPosition
    = LockToLeft
    | LockToRight
    | NoPositionLock


{-| Possible options to pin a column.
-}
type PinningType
    = PinnedToLeft
    | PinnedToRight
    | Unpinned


{-| The `Renderer` expresses how the data is retrieved from the list of data
and rendered to the view.

The editor and renderer views in the table depend on the type.
For example, a `BoolRenderer` is displayed and can be edited with a checkbox
in the table.

The `Renderer` may need a function to read the value for the cell from the
records.


### Example

If the data is list of `Product`, the `Renderer` to display the column for
the `title` might be defined as:

    type alias Product =
        { title : String }

    -- Column definitions:
    [{ renderer = StringRenderer .title, ... }]

-}
type Renderer dataType
    = AppRenderer { componentName : String, componentParams : Maybe Json.Encode.Value } (dataType -> String)
    | BoolRenderer (dataType -> Bool)
    | CurrencyRenderer { countryCode : String, currency : String } (dataType -> Maybe String)
    | DecimalRenderer { countryCode : String, decimalPlaces : Int } (dataType -> Maybe String)
    | FloatRenderer (dataType -> Float)
    | GroupRenderer (dataType -> String)
    | IntRenderer (dataType -> Int)
    | MaybeFloatRenderer (dataType -> Maybe Float)
    | MaybeIntRenderer (dataType -> Maybe Int)
    | MaybeStringRenderer (dataType -> Maybe String)
    | DateRenderer (dataType -> String)
    | NoRenderer
    | PercentRenderer { countryCode : String, decimalPlaces : Int } (dataType -> Maybe String)
    | SelectionRenderer (dataType -> String) (List String)
    | StringRenderer (dataType -> String)


{-| Row Group Panel allows the users to control which columns the rows are grouped by.
-}
type RowGroupPanelVisibility
    = AlwaysVisible
    | NeverVisible
    | OnlyWhenGroupingVisible


{-| Type of row selection, set to either `SingleRowSelection` or `MultipleRowSelection` to enable selection.

  - `SingleRowSelection` will use single row selection, such that when you select a row, any previously selected row gets unselected.
  - `MultipleRowSelection` allows multiple rows to be selected.
  - `NoRowSelection` will not perform a row selection, only selecting the cell.

-}
type RowSelection
    = MultipleRowSelection
    | NoRowSelection
    | SingleRowSelection


{-| Possible options for displayed sidebars.
-}
type SidebarType
    = ColumnSidebar
    | FilterSidebar


{-| Position for the sidebar.
-}
type SidebarPosition
    = SidebarLeft
    | SidebarRight


{-| Possible pre-configured column sorting.
-}
type Sorting
    = SortAscending
    | SortDescending
    | NoSorting


{-| CellEditor

  - `DefaultEditor` will set an editor derived from the renderer
  - `PredefinedEditor` allows to use an existing ag-grid editor
  - `AppEditor` allows to use an Elm app as custom editor

-}
type CellEditor
    = AppEditor { componentName : String, componentParams : Maybe Json.Encode.Value }
    | PredefinedEditor String
    | DefaultEditor


type alias CellEditorParams =
    { values : List String }


{-| Column definition.

Requires `field`, `renderer`, `headerName`, and `settings` to be defined
for each column.

  - `field`: name of the column and specifically used to decode data
    properly (e.g. from events)

  - `renderer`: used to render data to a cell (for more information see
    the documentation for `Renderer`)

  - `headerName`: displayed text in the column header

  - `settings`: allows to customize each column - a `defaultSettings`
    record is offered, which can be adjusted to your own needs to reduce
    the implemenation overhead.


### Example

    let
        defaultSettings =
            AgGrid.defaultSettings
    in
    [ { field = "id"
      , renderer = IntRenderer .id
      , headerName = "Id"
      , settings = defaultSettings
      }
    , { field = "title"
      , renderer = StringRenderer .title
      , headerName = "Product"
      , settings =
            { defaultSettings
                | editable = False
                , pinned = AgGrid.PinnedToLeft
            }
      }
    ]

-}
type alias ColumnDef dataType =
    { field : String
    , renderer : Renderer dataType
    , headerName : String
    , settings : ColumnSettings
    }


{-| Column configuration settings.
-}
type alias ColumnSettings =
    { aggFunc : Aggregation
    , allowedAggFuncs : Maybe (List Aggregation)
    , defaultAggFunc : Aggregation
    , autoHeaderHeight : Bool
    , cellClassRules : List ( String, Expression.Eval Bool )
    , checkboxSelection : Bool
    , customCellEditor : CellEditor
    , editable : Eval Bool
    , enablePivot : Bool
    , enableRowGroup : Bool
    , enableValue : Bool
    , filter : FilterType
    , filterParams :
        { buttons : List FilterButtonType
        , closeOnApply : Bool
        }
    , filterValueGetter : Maybe String
    , flex : Maybe Int
    , floatingFilter : Bool
    , headerCheckboxSelection : Bool
    , hide : Bool
    , lockPosition : LockPosition
    , minWidth : Maybe Int
    , pinned : PinningType
    , pivot : Bool
    , pivotIndex : Maybe Int
    , resizable : Bool
    , rowGroup : Bool
    , rowGroupIndex : Maybe Int
    , showDisabledCheckboxes : Bool
    , sortable : Bool
    , sort : Sorting
    , sortIndex : Maybe Int
    , suppressColumnsToolPanel : Bool
    , suppressFiltersToolPanel : Bool
    , suppressMenu : Bool
    , suppressSizeToFit : Bool
    , valueFormatter : Maybe String
    , valueGetter : Maybe String
    , valueParser : Maybe String
    , valueSetter : Maybe String
    , width : Maybe Float
    , wrapHeaderText : Bool
    }


{-| Column state.

Can be used to evaluate the current table state whenever a change to the structure of the table
happens (e.g. sorting, order, sizing, or visiblity of columns changed).

Might be used to persist the table state of the user to the localstorage or some other external
storage. Column states can be restored through the `columnState` on the `GridConfig`.

-}
type alias ColumnState =
    { aggFunc : Maybe String
    , colId : String
    , flex : Maybe Int
    , hide : Maybe Bool
    , pinned : Maybe String
    , pivot : Maybe Bool
    , pivotIndex : Maybe Int
    , rowGroup : Maybe Bool
    , rowGroupIndex : Maybe Int
    , sort : Maybe String
    , sortIndex : Maybe Int
    , width : Float
    }


{-| Filter state.

Can be used to evaluate the current filter configuration whenever a filter on a column gets changed.

Might be used to persist the filters applied to the table for the users to the localstorage or some
other external storage. Filter states can be restored through the `filterState` on the `GridConfig`.

AG Grid reference: <https://www.ag-grid.com/javascript-data-grid/filtering/#column-filter-types>

-}
type FilterState
    = TextFilterState TextFilterAttrs
    | NumberFilterState NumberFilterAttrs
    | DateFilterState DateFilterAttrs
    | SetFilterState SetFilterAttrs


type alias TextFilterAttrs =
    { filter : Maybe String
    , type_ : Maybe String
    , operator : Maybe String
    , condition1 : Maybe TextFilterCondition
    , condition2 : Maybe TextFilterCondition
    }


type alias TextFilterCondition =
    { type_ : String
    , filter : String
    }


type alias NumberFilterAttrs =
    { filter : Maybe Int
    , type_ : Maybe String
    , operator : Maybe String
    , condition1 : Maybe NumberFilterCondition
    , condition2 : Maybe NumberFilterCondition
    }


type alias NumberFilterCondition =
    { type_ : String
    , filter : Int
    }


type alias DateFilterAttrs =
    { dateFrom : Maybe String
    , dateTo : Maybe String
    , type_ : Maybe String
    , operator : Maybe String
    , condition1 : Maybe DateFilterCondition
    , condition2 : Maybe DateFilterCondition
    }


type alias DateFilterCondition =
    { dateFrom : Maybe String
    , dateTo : Maybe String
    , type_ : String
    }


type alias SetFilterAttrs =
    { values : List String
    }


{-| Grid configurations.
-}
type alias GridConfig dataType =
    { autoGroupColumnDef :
        { cellRendererParams :
            { suppressCount : Bool
            , checkbox : Bool
            }
        , headerName : Maybe String
        , minWidth : Maybe Int
        , resizable : Bool
        }
    , autoSizeColumns : Bool
    , cacheQuickFilter : Bool
    , columnStates : List ColumnState
    , contextMenu : Maybe ContextMenu
    , csvExport : Maybe CsvExportParams
    , detailRenderer :
        Maybe
            { componentName : String
            , componentParams : Maybe Json.Encode.Value
            , rowHeight : Maybe Int
            }
    , disableResizeOnScroll : Bool
    , excelExport : Maybe ExcelExportParams
    , filterStates : Dict.Dict String FilterState
    , groupDefaultExpanded : Int
    , groupIncludeFooter : Bool
    , groupIncludeTotalFooter : Bool
    , groupSelectsChildren : Bool
    , isRowSelectable : dataType -> Bool
    , maintainColumnOrder : Bool
    , pagination : Bool
    , quickFilterText : String
    , rowGroupPanelShow : RowGroupPanelVisibility
    , rowHeight : Maybe Int
    , rowId : Maybe (dataType -> String)
    , rowMultiSelectWithClick : Bool
    , rowSelection : RowSelection
    , selectedIds : List String
    , sideBar : Sidebar
    , size : String
    , sizeToFitAfterFirstDataRendered : Bool
    , stopEditingWhenCellsLoseFocus : Bool
    , suppressMenuHide : Bool
    , suppressRowClickSelection : Bool
    , suppressRowDeselection : Bool
    , themeClasses : Maybe String
    }


{-| Change event data for a table state changes.
-}
type alias StateChange type_ =
    { event : { type_ : EventType }
    , states : type_
    }


{-| Sidebar configuration.
-}
type alias Sidebar =
    { panels : List SidebarType
    , defaultToolPanel : Maybe SidebarType
    , position : SidebarPosition
    }



-- Defaults


{-| Retrieve a `ColumnSettings` record with default configuration.

Can be used when implementing column configurations for the table.

Default column settings:

    { aggFunc = NoAggregation
    , allowedAggFuncs = Nothing
    , defaultAggFunc = SumAggregation
    , autoHeaderHeight = False
    , cellClassRules = []
    , checkboxSelection = False
    , customCellEditor = DefaultEditor
    , editable = Const False
    , enablePivot = True
    , enableRowGroup = True
    , enableValue = True
    , filter = DefaultFilter
    , filterParams =
        { buttons = [ ClearButton ]
        , closeOnApply = False
        }
    , filterValueGetter = Nothing
    , flex = Nothing
    , floatingFilter = False
    , headerCheckboxSelection = False
    , hide = False
    , lockPosition = NoPositionLock
    , minWidth = Nothing
    , pinned = Unpinned
    , pivot = False
    , pivotIndex = Nothing
    , resizable = True
    , rowGroup = False
    , rowGroupIndex = Nothing
    , showDisabledCheckboxes = False
    , sortable = True
    , sort = NoSorting
    , sortIndex = Nothing
    , suppressColumnsToolPanel = False
    , suppressFiltersToolPanel = False
    , suppressMenu = False
    , suppressSizeToFit = True
    , valueFormatter = Nothing
    , valueGetter = Nothing
    , valueParser = Nothing
    , valueSetter = Nothing
    , width = Nothing
    , wrapHeaderText = False
    }

-}
defaultSettings : ColumnSettings
defaultSettings =
    { aggFunc = NoAggregation
    , allowedAggFuncs = Nothing
    , defaultAggFunc = SumAggregation
    , autoHeaderHeight = False
    , cellClassRules = []
    , checkboxSelection = False
    , customCellEditor = DefaultEditor
    , editable = Const False
    , enablePivot = True
    , enableRowGroup = True
    , enableValue = True
    , filter = DefaultFilter
    , filterParams =
        { buttons = [ ClearButton ]
        , closeOnApply = False
        }
    , filterValueGetter = Nothing
    , flex = Nothing
    , floatingFilter = False
    , headerCheckboxSelection = False
    , hide = False
    , lockPosition = NoPositionLock
    , minWidth = Nothing
    , pinned = Unpinned
    , pivot = False
    , pivotIndex = Nothing
    , resizable = True
    , rowGroup = False
    , rowGroupIndex = Nothing
    , showDisabledCheckboxes = False
    , sortable = True
    , sort = NoSorting
    , sortIndex = Nothing
    , suppressColumnsToolPanel = False
    , suppressFiltersToolPanel = False
    , suppressMenu = False
    , suppressSizeToFit = True
    , valueFormatter = Nothing
    , valueGetter = Nothing
    , valueParser = Nothing
    , valueSetter = Nothing
    , width = Nothing
    , wrapHeaderText = False
    }


{-| Retrieve a `GridConfig` record with default configuration.

Can be used when implementing the grid.

        { autoGroupColumnDef =
            { cellRendererParams =
                { suppressCount = False
                , checkbox = False
                }
            , headerName = Nothing
            , minWidth = Nothing
            , resizable = True
            }
        , autoSizeColumns = False
        , cacheQuickFilter = False
        , columnStates = []
        , detailRenderer = Nothing
        , disableResizeOnScroll = False
        , filterStates = Dict.empty
        , groupDefaultExpanded = 0
        , groupIncludeFooter = False
        , groupIncludeTotalFooter = False
        , groupSelectsChildren = False
        , isRowSelectable = always True
        , pagination = False
        , quickFilterText = ""
        , rowGroupPanelShow = NeverVisible
        , rowHeight = Nothing
        , rowMultiSelectWithClick = False
        , rowSelection = MultipleRowSelection
        , selectedIds = []
        , sideBar = defaultSidebar
        , size = "65vh"
        , sizeToFitAfterFirstDataRendered = True
        , stopEditingWhenCellsLoseFocus = True
        , suppressMenuHide = False
        , suppressRowClickSelection = False
        , suppressRowDeselection = False
        , themeClasses = Nothing
        }

-}
defaultGridConfig : GridConfig dataType
defaultGridConfig =
    { autoGroupColumnDef =
        { cellRendererParams =
            { suppressCount = False
            , checkbox = False
            }
        , headerName = Nothing
        , minWidth = Nothing
        , resizable = True
        }
    , autoSizeColumns = False
    , cacheQuickFilter = False
    , columnStates = []
    , contextMenu =
        Just
            [ ContextMenu.cutContextAction
            , ContextMenu.copyContextAction
            , ContextMenu.copyWithHeadersContextAction
            , ContextMenu.copyWithGroupHeadersContextAction
            , ContextMenu.pasteContextAction
            , ContextMenu.excelExportContextAction
            , ContextMenu.csvExportContextAction
            ]
    , csvExport = Nothing
    , detailRenderer = Nothing
    , disableResizeOnScroll = False
    , excelExport = Nothing
    , filterStates = Dict.empty
    , groupDefaultExpanded = 0
    , groupIncludeFooter = False
    , groupIncludeTotalFooter = False
    , groupSelectsChildren = False
    , isRowSelectable = always True
    , maintainColumnOrder = False
    , pagination = False
    , quickFilterText = ""
    , rowGroupPanelShow = NeverVisible
    , rowHeight = Nothing
    , rowId = Nothing
    , rowMultiSelectWithClick = False
    , rowSelection = MultipleRowSelection
    , selectedIds = []
    , sideBar = defaultSidebar
    , size = "65vh"
    , sizeToFitAfterFirstDataRendered = True
    , stopEditingWhenCellsLoseFocus = True
    , suppressMenuHide = False
    , suppressRowClickSelection = False
    , suppressRowDeselection = False
    , themeClasses = Nothing
    }


{-| Retrieve a `Sidebar` with default configuration.

Can be used to ease the sidebar configuration.

        { panels = []
        , defaultToolPanel = Nothing
        , position = SidebarRight
        }

-}
defaultSidebar : Sidebar
defaultSidebar =
    { panels = []
    , defaultToolPanel = Nothing
    , position = SidebarRight
    }



-- Grid


{-| Defines the data grid.


## Example

    let
        gridConfig =
            AgGrid.defaultGridConfig
                |> (\config -> { config | themeClasses = Just "ag-theme-balham ag-basic" })

        events =
            [ onCellChanged rowDecoder UpdateProduct ]

        defaultSettings =
            AgGrid.defaultSettings
                |> (\settings -> { settings | editable = True })

        columns =
            [ { field = "id"
              , renderer = IntRenderer .id
              , headerName = "Id"
              , settings = { defaultSettings | enablePivot = False }
              }
            , { field = "title"
              , renderer = StringRenderer .title
              , headerName = "Product"
              , settings = { defaultSettings | filter = StringFilter }
              }
            ]

        data =
            model.products
    in
    grid gridConfig events columns data

-}
grid : GridConfig dataType -> List (Html.Attribute msg) -> List (ColumnDef dataType) -> List dataType -> Html msg
grid gridConfig events columnDefs data =
    let
        columns =
            columnDefs
                |> prepareColumns gridConfig
                |> applyColumnState gridConfig
                |> Json.Encode.list (columnDefEncoder gridConfig)
                |> Json.Encode.encode 0

        configAttributes =
            generateGridConfigAttributes gridConfig
    in
    node "ag-grid"
        ([ id "ag-grid"
         , attribute "columnDefs" columns
         , attribute "rowData" (encodeData gridConfig columnDefs data)
         ]
            ++ configAttributes
            ++ events
        )
        []


{-| Apply the column state from the `GridConfig` to the given `ColumnDefs`.

The values from the cache overwrite the values on the ColumnDef. The order is also according
to the order in the column state. New columns, that don't exist in the column state, are appended to the end.

**This function is mainly exposed to allow unit-testing, as this is automatically applied to ColumnDefs passed to the `grid`.**

-}
applyColumnState : GridConfig dataType -> List (ColumnDef dataType) -> List (ColumnDef dataType)
applyColumnState gridConfig columnDefs =
    let
        indexedStorage : Dict.Dict String ( Int, ColumnState )
        indexedStorage =
            gridConfig.columnStates
                |> List.indexedMap Tuple.pair
                |> List.map (\( index, col ) -> ( col.colId, ( index, col ) ))
                |> Dict.fromList

        applyCache : ColumnDef dataType -> ColumnState -> ColumnDef dataType
        applyCache ({ settings } as column) cachedState =
            { column
                | settings =
                    { settings
                        | aggFunc = toAggregation cachedState.aggFunc
                        , flex = cachedState.flex
                        , hide = Maybe.withDefault settings.hide cachedState.hide
                        , pinned = toPinningType cachedState.pinned
                        , pivot = Maybe.withDefault settings.pivot cachedState.pivot
                        , pivotIndex = cachedState.pivotIndex
                        , rowGroup = Maybe.withDefault settings.rowGroup cachedState.rowGroup
                        , rowGroupIndex = cachedState.rowGroupIndex
                        , sort = toSorting cachedState.sort
                        , sortIndex = cachedState.sortIndex
                        , width = Just cachedState.width
                    }
            }

        sorter : ( Maybe Int, any ) -> ( Maybe Int, any ) -> Order
        sorter ( position1, _ ) ( position2, _ ) =
            case ( position1, position2 ) of
                ( Just pos1, Just pos2 ) ->
                    compare pos1 pos2

                ( Nothing, Just _ ) ->
                    GT

                ( Just _, Nothing ) ->
                    LT

                ( Nothing, Nothing ) ->
                    EQ
    in
    columnDefs
        |> List.map
            (\column ->
                case Dict.get column.field indexedStorage of
                    Just ( position, cachedState ) ->
                        ( Just position, applyCache column cachedState )

                    Nothing ->
                        ( Nothing, column )
            )
        |> List.sortWith sorter
        |> List.map Tuple.second


prepareColumns : GridConfig dataType -> List (ColumnDef dataType) -> List (ColumnDef dataType)
prepareColumns gridConfig columnDefs =
    if not gridConfig.autoSizeColumns then
        -- If columns are not automatically sized, we insert another (empty) column that
        -- fills out the remaining width space of the table.
        List.append columnDefs
            [ { field = "table-filler-cell"
              , renderer = NoRenderer
              , headerName = ""
              , settings =
                    { defaultSettings
                        | enablePivot = False
                        , enableRowGroup = False
                        , enableValue = False
                        , filter = NoFilter
                        , suppressColumnsToolPanel = True
                        , suppressFiltersToolPanel = True
                        , suppressMenu = True
                        , suppressSizeToFit = False
                    }
              }
            ]

    else
        columnDefs



-- Eventhandler


{-| Detect change events on cells.

Decodes the changed row according to the provided `dataDecoder` and passes the result to
the message `toMsg`.

Handles the `cellValueChanged` event from Ag Grid.

-}
onCellChanged : Decoder dataType -> (Result Decode.Error dataType -> msg) -> Html.Attribute msg
onCellChanged dataDecoder toMsg =
    cellUpdateDecoder
        |> Decode.map (Decode.decodeValue dataDecoder)
        |> Decode.map toMsg
        |> Html.Events.on "cellvaluechanged"


{-| Detect doubleclick events on cells.

Decodes the row of the clicked cell according to the provided `dataDecoder` and the field
name of the clicked cells as tuple and passes the result to the message `toMsg`.

Handles the `cellDoubleClicked` event from Ag Grid.

-}
onCellDoubleClicked : Decoder dataType -> (( Result Decode.Error dataType, String ) -> msg) -> Html.Attribute msg
onCellDoubleClicked dataDecoder toMsg =
    let
        valueDecoder =
            Decode.at [ "agGridDetails", "data" ] Decode.value
                |> Decode.map (Decode.decodeValue dataDecoder)

        elementDecoder =
            Decode.at [ "agGridDetails", "event", "srcElement", "attributes", "col-id", "value" ] Decode.string

        event =
            Decode.map2 (\v e -> toMsg <| Tuple.pair v e) valueDecoder elementDecoder
    in
    Html.Events.on "celldoubleclicked" event


{-| Detect click on custom context menu actions
-}
onContextMenu : Decoder dataType -> (( Result Decode.Error dataType, String ) -> msg) -> Html.Attribute msg
onContextMenu dataDecoder toMsg =
    let
        actionDecoder =
            Decode.at [ "detail", "action" ] Decode.string

        elementDecoder =
            Decode.at [ "detail", "data" ] Decode.value
                |> Decode.map (Decode.decodeValue dataDecoder)

        event =
            Decode.map2 (\v e -> toMsg <| Tuple.pair v e) elementDecoder actionDecoder
    in
    Html.Events.on "contextActionClicked" event


{-| Detect change events to the table structure (e.g. sorting or moved columns).

Decodes the `EventType` of the change and the current states of the grid columns and passes
the result to the `toMsg`.

-}
onColumnStateChanged : (StateChange (List ColumnState) -> msg) -> Html.Attribute msg
onColumnStateChanged toMsg =
    let
        statesDecoder =
            Decode.at [ "detail", "columnState" ] (Decode.list columnStateDecoder)
    in
    Decode.map2 (\type_ states -> { event = { type_ = type_ }, states = states }) eventTypeDecoder statesDecoder
        |> Decode.map toMsg
        |> Html.Events.on "columnStateChanged"


{-| Detect change events to the table filters.

Decodes the `EventType` of the change and the filter configuration of the grid columns and passes
the result to the `toMsg`.

-}
onFilterStateChanged : (StateChange (Dict.Dict String FilterState) -> msg) -> Html.Attribute msg
onFilterStateChanged toMsg =
    let
        statesDecoder =
            Decode.at [ "detail", "filterState" ] filterStatesDecoder
    in
    Decode.map2 (\type_ states -> { event = { type_ = type_ }, states = states }) eventTypeDecoder statesDecoder
        |> Decode.map toMsg
        |> Html.Events.on "filterStateChanged"


{-| Detect selection change events.

Sends the current selection of [nodes](https://www.ag-grid.com/javascript-data-grid/row-object/) to the `toMsg`.

-}
onSelectionChange : Decoder node -> (Result Decode.Error (List node) -> msg) -> Html.Attribute msg
onSelectionChange nodeDecoder toMsg =
    let
        nodesDecoder =
            Decode.list nodeDecoder
    in
    Html.Events.on "selectionChanged"
        (Decode.at [ "detail", "nodes" ] Decode.value
            |> Decode.map (Decode.decodeValue nodesDecoder)
            |> Decode.map toMsg
        )



-- Encoding/Decoding


cellEditorParamsEncoder : CellEditorParams -> Json.Encode.Value
cellEditorParamsEncoder params =
    Json.Encode.object
        [ ( "values", Json.Encode.list Json.Encode.string params.values )
        ]


columnDefEncoder : GridConfig dataType -> ColumnDef dataType -> Json.Encode.Value
columnDefEncoder gridConfig columnDef =
    let
        { encodedFilter, encodedFilterValueGetter } =
            encodeFilterProperties columnDef
    in
    Json.Encode.object
        [ ( "aggFunc", encodeMaybe Json.Encode.string (aggregationToString columnDef.settings.aggFunc) )
        , ( "allowedAggFuncs", encodeMaybe (List.filterMap aggregationToString >> Json.Encode.list Json.Encode.string) columnDef.settings.allowedAggFuncs )
        , ( "defaultAggFunc", encodeMaybe Json.Encode.string (aggregationToString columnDef.settings.defaultAggFunc) )
        , ( "autoHeaderHeight", Json.Encode.bool columnDef.settings.autoHeaderHeight )
        , ( "cellClassRules"
          , Json.Encode.object <|
                List.map (\( class, expression ) -> ( class, Expression.encode Json.Encode.bool expression )) columnDef.settings.cellClassRules
          )
        , ( "checkboxSelection", Json.Encode.bool columnDef.settings.checkboxSelection )
        , ( "cellRenderer"
          , case columnDef.renderer of
                AppRenderer _ _ ->
                    Json.Encode.string "appRenderer"

                BoolRenderer _ ->
                    Json.Encode.string "booleanCellRenderer"

                GroupRenderer _ ->
                    Json.Encode.string "agGroupCellRenderer"

                _ ->
                    Json.Encode.null
          )
        , ( "cellRendererParams"
          , case columnDef.renderer of
                AppRenderer params _ ->
                    Json.Encode.object
                        [ ( "componentName", Json.Encode.string params.componentName )
                        , ( "componentParams", Maybe.withDefault Json.Encode.null params.componentParams )
                        ]

                _ ->
                    Json.Encode.null
          )
        , ( "cellEditor"
          , case ( columnDef.settings.customCellEditor, columnDef.renderer ) of
                ( DefaultEditor, BoolRenderer _ ) ->
                    Json.Encode.string "booleanCellEditor"

                ( DefaultEditor, CurrencyRenderer _ _ ) ->
                    Json.Encode.string "decimalEditor"

                ( DefaultEditor, DecimalRenderer _ _ ) ->
                    Json.Encode.string "decimalEditor"

                ( DefaultEditor, PercentRenderer _ _ ) ->
                    Json.Encode.string "decimalEditor"

                ( DefaultEditor, SelectionRenderer _ _ ) ->
                    Json.Encode.string "agRichSelectCellEditor"

                ( PredefinedEditor editorName, _ ) ->
                    Json.Encode.string editorName

                ( AppEditor _, _ ) ->
                    Json.Encode.string "appEditor"

                _ ->
                    Json.Encode.null
          )
        , ( "cellEditorParams"
          , case ( columnDef.settings.customCellEditor, columnDef.renderer ) of
                ( DefaultEditor, CurrencyRenderer { countryCode } _ ) ->
                    Json.Encode.object
                        [ ( "countryCode", Json.Encode.string countryCode )
                        , ( "decimalPlaces", Json.Encode.int 2 )
                        ]

                ( DefaultEditor, DecimalRenderer { countryCode, decimalPlaces } _ ) ->
                    Json.Encode.object
                        [ ( "countryCode", Json.Encode.string countryCode )
                        , ( "decimalPlaces", Json.Encode.int decimalPlaces )
                        ]

                ( DefaultEditor, PercentRenderer { countryCode, decimalPlaces } _ ) ->
                    Json.Encode.object
                        [ ( "countryCode", Json.Encode.string countryCode )
                        , ( "decimalPlaces", Json.Encode.int decimalPlaces )
                        ]

                ( DefaultEditor, SelectionRenderer _ collection ) ->
                    cellEditorParamsEncoder { values = collection }

                ( AppEditor params, _ ) ->
                    Json.Encode.object
                        [ ( "componentName", Json.Encode.string params.componentName )
                        , ( "componentParams", Maybe.withDefault Json.Encode.null params.componentParams )
                        ]

                _ ->
                    Json.Encode.null
          )
        , ( "editable", Expression.encode Json.Encode.bool columnDef.settings.editable )
        , ( "enablePivot", Json.Encode.bool columnDef.settings.enablePivot )
        , ( "enableRowGroup", Json.Encode.bool columnDef.settings.enableRowGroup )
        , ( "enableValue", Json.Encode.bool columnDef.settings.enableValue )
        , ( "field", Json.Encode.string columnDef.field )
        , ( "filter", encodedFilter )
        , ( "filterParams"
          , Json.Encode.object
                [ ( "buttons", Json.Encode.list encodeFilterButtonType columnDef.settings.filterParams.buttons )
                ]
          )
        , ( "filterValueGetter", encodedFilterValueGetter )
        , ( "flex", encodeMaybe Json.Encode.int columnDef.settings.flex )
        , ( "floatingFilter", Json.Encode.bool columnDef.settings.floatingFilter )
        , ( "headerCheckboxSelection", Json.Encode.bool columnDef.settings.headerCheckboxSelection )
        , ( "headerName", Json.Encode.string columnDef.headerName )
        , ( "hide", Json.Encode.bool columnDef.settings.hide )
        , ( "lockPosition"
          , case columnDef.settings.lockPosition of
                LockToLeft ->
                    Json.Encode.string "left"

                LockToRight ->
                    Json.Encode.string "right"

                NoPositionLock ->
                    Json.Encode.null
          )
        , ( "minWidth", encodeMaybe Json.Encode.int columnDef.settings.minWidth )
        , ( "pinned", encodeMaybe Json.Encode.string (pinningTypeToString columnDef.settings.pinned) )
        , ( "pivot", Json.Encode.bool columnDef.settings.pivot )
        , ( "pivotIndex", encodeMaybe Json.Encode.int columnDef.settings.pivotIndex )
        , ( "resizable", Json.Encode.bool columnDef.settings.resizable )
        , ( "rowGroup", Json.Encode.bool columnDef.settings.rowGroup )
        , ( "rowGroupIndex", encodeMaybe Json.Encode.int columnDef.settings.rowGroupIndex )
        , ( "sortable", Json.Encode.bool columnDef.settings.sortable )
        , ( "sort", encodeMaybe Json.Encode.string (sortingToString columnDef.settings.sort) )
        , ( "sortIndex", encodeMaybe Json.Encode.int columnDef.settings.sortIndex )
        , ( "showDisabledCheckboxes", Json.Encode.bool columnDef.settings.showDisabledCheckboxes )
        , ( "suppressColumnsToolPanel", Json.Encode.bool columnDef.settings.suppressColumnsToolPanel )
        , ( "suppressFiltersToolPanel", Json.Encode.bool columnDef.settings.suppressFiltersToolPanel )
        , ( "suppressSizeToFit"
          , Json.Encode.bool <|
                if gridConfig.autoSizeColumns then
                    False

                else
                    columnDef.settings.suppressSizeToFit
          )
        , ( "suppressMenu", Json.Encode.bool columnDef.settings.suppressMenu )
        , ( "valueFormatter"
          , case ( columnDef.settings.valueFormatter, columnDef.renderer ) of
                ( Just overwrittenFormatter, _ ) ->
                    Json.Encode.string overwrittenFormatter

                ( Nothing, CurrencyRenderer config _ ) ->
                    Json.Encode.string (ValueFormat.currencyValueFormatter config)

                ( Nothing, DecimalRenderer config _ ) ->
                    Json.Encode.string (ValueFormat.decimalValueFormatter config)

                ( Nothing, PercentRenderer config _ ) ->
                    Json.Encode.string (ValueFormat.percentValueFormatter config)

                ( Nothing, _ ) ->
                    Json.Encode.null
          )
        , ( "valueGetter"
          , case ( columnDef.settings.valueGetter, columnDef.renderer ) of
                ( Just overwrittenFormatter, _ ) ->
                    Json.Encode.string overwrittenFormatter

                ( Nothing, CurrencyRenderer _ _ ) ->
                    Json.Encode.string (ValueFormat.numberValueGetter columnDef.field)

                ( Nothing, DecimalRenderer _ _ ) ->
                    Json.Encode.string (ValueFormat.numberValueGetter columnDef.field)

                ( Nothing, PercentRenderer _ _ ) ->
                    Json.Encode.string (ValueFormat.numberValueGetter columnDef.field)

                ( Nothing, _ ) ->
                    Json.Encode.null
          )
        , ( "valueParser"
          , case ( columnDef.settings.valueParser, columnDef.renderer ) of
                ( Just overwrittenFormatter, _ ) ->
                    Json.Encode.string overwrittenFormatter

                ( Nothing, _ ) ->
                    Json.Encode.null
          )
        , ( "valueSetter", encodeMaybe Json.Encode.string columnDef.settings.valueSetter )
        , ( "width"
          , case columnDef.settings.width of
                Just width ->
                    Json.Encode.float width

                Nothing ->
                    Json.Encode.null
          )
        , ( "wrapHeaderText", Json.Encode.bool columnDef.settings.wrapHeaderText )
        ]


columnStateDecoder : Decoder ColumnState
columnStateDecoder =
    Decode.succeed ColumnState
        |> DecodePipeline.optional "aggFunc" (Decode.nullable Decode.string) Nothing
        |> DecodePipeline.required "colId" Decode.string
        |> DecodePipeline.optional "flex" (Decode.nullable Decode.int) Nothing
        |> DecodePipeline.optional "hide" (Decode.nullable Decode.bool) Nothing
        |> DecodePipeline.optional "pinned" (Decode.nullable Decode.string) Nothing
        |> DecodePipeline.optional "pivot" (Decode.nullable Decode.bool) Nothing
        |> DecodePipeline.optional "pivotIndex" (Decode.nullable Decode.int) Nothing
        |> DecodePipeline.optional "rowGroup" (Decode.nullable Decode.bool) Nothing
        |> DecodePipeline.optional "rowGroupIndex" (Decode.nullable Decode.int) Nothing
        |> DecodePipeline.optional "sort" (Decode.nullable Decode.string) Nothing
        |> DecodePipeline.optional "sortIndex" (Decode.nullable Decode.int) Nothing
        |> DecodePipeline.required "width" Decode.float


{-| Decoder for the current column states.

Can be used to retrieve and decode the column states from an external storage.

-}
columnStatesDecoder : Decoder (List ColumnState)
columnStatesDecoder =
    Decode.oneOf [ Decode.list columnStateDecoder, Decode.null [] ]


filterStateDecoder : Decoder FilterState
filterStateDecoder =
    Decode.field "filterType" Decode.string
        |> Decode.andThen
            (\filterType ->
                case filterType of
                    "date" ->
                        Decode.map DateFilterState dateFilterDecoder

                    "number" ->
                        Decode.map NumberFilterState numberFilterDecoder

                    "set" ->
                        Decode.map SetFilterState setFilterDecoder

                    "text" ->
                        Decode.map TextFilterState textFilterDecoder

                    _ ->
                        Decode.fail <| "unknown filter state type: " ++ filterType
            )


textFilterDecoder : Decoder TextFilterAttrs
textFilterDecoder =
    Decode.succeed TextFilterAttrs
        |> DecodePipeline.optional "filter" (Decode.nullable Decode.string) Nothing
        |> DecodePipeline.optional "type" (Decode.nullable Decode.string) Nothing
        |> DecodePipeline.optional "operator" (Decode.nullable Decode.string) Nothing
        |> DecodePipeline.optional "condition1" (Decode.nullable textFilterConditionDecoder) Nothing
        |> DecodePipeline.optional "condition2" (Decode.nullable textFilterConditionDecoder) Nothing


textFilterConditionDecoder : Decoder TextFilterCondition
textFilterConditionDecoder =
    Decode.succeed TextFilterCondition
        |> DecodePipeline.required "type" Decode.string
        |> DecodePipeline.required "filter" Decode.string


numberFilterDecoder : Decoder NumberFilterAttrs
numberFilterDecoder =
    Decode.succeed NumberFilterAttrs
        |> DecodePipeline.optional "filter" (Decode.nullable Decode.int) Nothing
        |> DecodePipeline.optional "type" (Decode.nullable Decode.string) Nothing
        |> DecodePipeline.optional "operator" (Decode.nullable Decode.string) Nothing
        |> DecodePipeline.optional "condition1" (Decode.nullable numberFilterConditionDecoder) Nothing
        |> DecodePipeline.optional "condition2" (Decode.nullable numberFilterConditionDecoder) Nothing


numberFilterConditionDecoder : Decoder NumberFilterCondition
numberFilterConditionDecoder =
    Decode.succeed NumberFilterCondition
        |> DecodePipeline.required "type" Decode.string
        |> DecodePipeline.required "filter" Decode.int


dateFilterDecoder : Decoder DateFilterAttrs
dateFilterDecoder =
    Decode.succeed DateFilterAttrs
        |> DecodePipeline.optional "dateFrom" (Decode.nullable Decode.string) Nothing
        |> DecodePipeline.optional "dateTo" (Decode.nullable Decode.string) Nothing
        |> DecodePipeline.optional "type" (Decode.nullable Decode.string) Nothing
        |> DecodePipeline.optional "operator" (Decode.nullable Decode.string) Nothing
        |> DecodePipeline.optional "condition1" (Decode.nullable dateFilterConditionDecoder) Nothing
        |> DecodePipeline.optional "condition2" (Decode.nullable dateFilterConditionDecoder) Nothing


dateFilterConditionDecoder : Decoder DateFilterCondition
dateFilterConditionDecoder =
    Decode.succeed DateFilterCondition
        |> DecodePipeline.optional "dateFrom" (Decode.nullable Decode.string) Nothing
        |> DecodePipeline.optional "dateTo" (Decode.nullable Decode.string) Nothing
        |> DecodePipeline.required "type" Decode.string


setFilterDecoder : Decoder SetFilterAttrs
setFilterDecoder =
    Decode.succeed SetFilterAttrs
        |> DecodePipeline.required "values" (Decode.list Decode.string)


{-| Decoder for the filter states.

Can be used to retrieve and decode the filter states from an external storage.

-}
filterStatesDecoder : Decoder (Dict.Dict String FilterState)
filterStatesDecoder =
    Decode.oneOf [ Decode.dict filterStateDecoder, Decode.null Dict.empty ]


{-| Encode a collection of `ColumnState`.

Can be used to persist the current list of `ColumnState` for the grid to an external storage.

-}
columnStatesEncoder : List ColumnState -> Json.Encode.Value
columnStatesEncoder =
    Json.Encode.list columnStateEncoder


columnStateEncoder : ColumnState -> Json.Encode.Value
columnStateEncoder columnState =
    Json.Encode.object
        [ ( "aggFunc", encodeMaybe Json.Encode.string columnState.aggFunc )
        , ( "colId", Json.Encode.string columnState.colId )
        , ( "flex", encodeMaybe Json.Encode.int columnState.flex )
        , ( "hide", encodeMaybe Json.Encode.bool columnState.hide )
        , ( "pinned", encodeMaybe Json.Encode.string columnState.pinned )
        , ( "pivot", encodeMaybe Json.Encode.bool columnState.pivot )
        , ( "pivotIndex", encodeMaybe Json.Encode.int columnState.pivotIndex )
        , ( "rowGroup", encodeMaybe Json.Encode.bool columnState.rowGroup )
        , ( "rowGroupIndex", encodeMaybe Json.Encode.int columnState.rowGroupIndex )
        , ( "sort", encodeMaybe Json.Encode.string columnState.sort )
        , ( "sortIndex", encodeMaybe Json.Encode.int columnState.sortIndex )
        , ( "width", Json.Encode.float columnState.width )
        ]


{-| Encode a collection of `FilterState`.

Can be used to persist the current collection of `FilterState` for the grid to an external storage.

-}
filterStatesEncoder : Dict.Dict String FilterState -> Json.Encode.Value
filterStatesEncoder =
    Json.Encode.dict identity filterStateEncoder


filterStateEncoder : FilterState -> Json.Encode.Value
filterStateEncoder filterState =
    case filterState of
        DateFilterState attrs ->
            Json.Encode.object
                [ ( "filterType", Json.Encode.string "date" )
                , ( "dateFrom", encodeMaybe Json.Encode.string attrs.dateFrom )
                , ( "dateTo", encodeMaybe Json.Encode.string attrs.dateTo )
                , ( "type", encodeMaybe Json.Encode.string attrs.type_ )
                , ( "operator", encodeMaybe Json.Encode.string attrs.operator )
                , ( "condition1", encodeMaybe dateFilterConditionEncoder attrs.condition1 )
                , ( "condition2", encodeMaybe dateFilterConditionEncoder attrs.condition2 )
                ]

        NumberFilterState attrs ->
            Json.Encode.object
                [ ( "filterType", Json.Encode.string "number" )
                , ( "filter", encodeMaybe Json.Encode.int attrs.filter )
                , ( "type", encodeMaybe Json.Encode.string attrs.type_ )
                , ( "operator", encodeMaybe Json.Encode.string attrs.operator )
                , ( "condition1", encodeMaybe numberFilterConditionEncoder attrs.condition1 )
                , ( "condition2", encodeMaybe numberFilterConditionEncoder attrs.condition2 )
                ]

        SetFilterState attrs ->
            Json.Encode.object
                [ ( "filterType", Json.Encode.string "set" )
                , ( "values", Json.Encode.list Json.Encode.string attrs.values )
                ]

        TextFilterState attrs ->
            Json.Encode.object
                [ ( "filterType", Json.Encode.string "text" )
                , ( "filter", encodeMaybe Json.Encode.string attrs.filter )
                , ( "type", encodeMaybe Json.Encode.string attrs.type_ )
                , ( "operator", encodeMaybe Json.Encode.string attrs.operator )
                , ( "condition1", encodeMaybe textFilterConditionEncoder attrs.condition1 )
                , ( "condition2", encodeMaybe textFilterConditionEncoder attrs.condition2 )
                ]


dateFilterConditionEncoder : DateFilterCondition -> Json.Encode.Value
dateFilterConditionEncoder condition =
    Json.Encode.object
        [ ( "filterType", Json.Encode.string "date" )
        , ( "type", Json.Encode.string condition.type_ )
        , ( "dateFrom", encodeMaybe Json.Encode.string condition.dateFrom )
        , ( "dateTo", encodeMaybe Json.Encode.string condition.dateTo )
        ]


textFilterConditionEncoder : TextFilterCondition -> Json.Encode.Value
textFilterConditionEncoder condition =
    Json.Encode.object
        [ ( "filterType", Json.Encode.string "text" )
        , ( "type", Json.Encode.string condition.type_ )
        , ( "filter", Json.Encode.string condition.filter )
        ]


numberFilterConditionEncoder : NumberFilterCondition -> Json.Encode.Value
numberFilterConditionEncoder condition =
    Json.Encode.object
        [ ( "filterType", Json.Encode.string "number" )
        , ( "type", Json.Encode.string condition.type_ )
        , ( "filter", Json.Encode.int condition.filter )
        ]


eventTypeDecoder : Decoder EventType
eventTypeDecoder =
    Decode.at [ "detail", "event", "type" ] Decode.string
        |> Decode.andThen
            (\value ->
                case value of
                    "columnMoved" ->
                        Decode.succeed ColumnMoved

                    "columnResized" ->
                        Decode.succeed ColumnResized

                    "columnVisible" ->
                        Decode.succeed ColumnVisible

                    "gridColumnsChanged" ->
                        Decode.succeed GridColumnsChanged

                    "sortChanged" ->
                        Decode.succeed SortChanged

                    "filterChanged" ->
                        Decode.succeed FilterChanged

                    "columnPinned" ->
                        Decode.succeed ColumnPinned

                    "columnRowGroupChanged" ->
                        Decode.succeed ColumnRowGroupChanged

                    "columnValueChanged" ->
                        Decode.succeed ColumnValueChanged

                    "resetColumns" ->
                        Decode.succeed ResetColumns

                    unexpectedType ->
                        Decode.fail ("unexpected event type: " ++ unexpectedType)
            )


generateGridConfigAttributes : GridConfig dataType -> List (Html.Attribute msg)
generateGridConfigAttributes gridConfig =
    let
        encodedConfigValues =
            [ ( "autoGroupColumnDef"
              , Json.Encode.object
                    [ ( "headerName", encodeMaybe Json.Encode.string gridConfig.autoGroupColumnDef.headerName )
                    , ( "minWidth", encodeMaybe Json.Encode.int gridConfig.autoGroupColumnDef.minWidth )
                    , ( "cellRendererParams"
                      , Json.Encode.object
                            [ ( "suppressCount", Json.Encode.bool gridConfig.autoGroupColumnDef.cellRendererParams.suppressCount )
                            , ( "checkbox", Json.Encode.bool gridConfig.autoGroupColumnDef.cellRendererParams.checkbox )
                            ]
                      )
                    , ( "resizable", Json.Encode.bool gridConfig.autoGroupColumnDef.resizable )
                    ]
              )
            , ( "autoSizeColumns", Json.Encode.bool gridConfig.autoSizeColumns )
            , ( "animateRows", Json.Encode.bool True )
            , ( "cacheQuickFilter", Json.Encode.bool gridConfig.cacheQuickFilter )
            , ( "columnState", columnStatesEncoder gridConfig.columnStates )
            , ( "customRowId", Json.Encode.bool (gridConfig.rowId /= Nothing) )
            , ( "detailCellRenderer"
              , case gridConfig.detailRenderer of
                    Just _ ->
                        Json.Encode.string "appRenderer"

                    Nothing ->
                        Json.Encode.null
              )
            , ( "detailCellRendererParams"
              , case gridConfig.detailRenderer of
                    Just { componentName, componentParams } ->
                        Json.Encode.object
                            [ ( "componentName", Json.Encode.string componentName )
                            , ( "componentParams", Maybe.withDefault Json.Encode.null componentParams )
                            ]

                    Nothing ->
                        Json.Encode.null
              )
            , ( "detailRowHeight"
              , gridConfig.detailRenderer
                    |> Maybe.andThen .rowHeight
                    |> encodeMaybe Json.Encode.int
              )
            , ( "defaultExcelExportParams", encodeMaybe encodeExcelExportParams gridConfig.excelExport )
            , ( "defaultCsvExportParams", encodeMaybe encodeCsvExportParams gridConfig.csvExport )
            , ( "filterState", filterStatesEncoder gridConfig.filterStates )
            , ( "headerHeight", Json.Encode.int 48 )
            , ( "getContextMenuItems", encodeMaybe ContextMenu.encode gridConfig.contextMenu )
            , ( "quickFilterText"
              , if String.isEmpty gridConfig.quickFilterText then
                    Json.Encode.null

                else
                    Json.Encode.string gridConfig.quickFilterText
              )
            , ( "disableResizeOnScroll", Json.Encode.bool gridConfig.disableResizeOnScroll )
            , ( "enableRangeSelection", Json.Encode.bool True )
            , ( "groupDefaultExpanded", Json.Encode.int gridConfig.groupDefaultExpanded )
            , ( "groupIncludeFooter", Json.Encode.bool gridConfig.groupIncludeFooter )
            , ( "groupIncludeTotalFooter", Json.Encode.bool gridConfig.groupIncludeTotalFooter )
            , ( "groupSelectsChildren", Json.Encode.bool gridConfig.groupSelectsChildren )
            , ( "maintainColumnOrder", Json.Encode.bool gridConfig.maintainColumnOrder )
            , ( "masterDetail"
              , Json.Encode.bool <|
                    case gridConfig.detailRenderer of
                        Just _ ->
                            True

                        Nothing ->
                            False
              )
            , ( "pagination", Json.Encode.bool gridConfig.pagination )
            , ( "rowHeight"
              , case gridConfig.rowHeight of
                    Just rowHeight ->
                        Json.Encode.int rowHeight

                    Nothing ->
                        Json.Encode.null
              )
            , ( "rowGroupPanelShow", encodeRowGroupPanelVisibility gridConfig.rowGroupPanelShow )
            , ( "rowMultiSelectWithClick", Json.Encode.bool gridConfig.rowMultiSelectWithClick )
            , ( "rowSelection"
              , case gridConfig.rowSelection of
                    MultipleRowSelection ->
                        Json.Encode.string "multiple"

                    SingleRowSelection ->
                        Json.Encode.string "single"

                    NoRowSelection ->
                        Json.Encode.null
              )
            , ( "selectedIds", Json.Encode.list Json.Encode.string gridConfig.selectedIds )
            , ( "sideBar"
              , Json.Encode.object
                    [ ( "toolPanels", Json.Encode.list encodeSidebarType gridConfig.sideBar.panels )
                    , ( "position"
                      , case gridConfig.sideBar.position of
                            SidebarLeft ->
                                Json.Encode.string "left"

                            SidebarRight ->
                                Json.Encode.string "right"
                      )
                    , ( "hiddenByDefault", Json.Encode.bool (List.isEmpty gridConfig.sideBar.panels) )
                    , ( "defaultToolPanel", encodeMaybe encodeSidebarType gridConfig.sideBar.defaultToolPanel )
                    ]
              )
            , ( "sizeToFitAfterFirstDataRendered", Json.Encode.bool gridConfig.sizeToFitAfterFirstDataRendered )
            , ( "stopEditingWhenCellsLoseFocus", Json.Encode.bool gridConfig.stopEditingWhenCellsLoseFocus )
            , ( "suppressMenuHide", Json.Encode.bool gridConfig.suppressMenuHide )
            , ( "suppressRowClickSelection", Json.Encode.bool gridConfig.suppressRowClickSelection )
            , ( "suppressRowDeselection", Json.Encode.bool gridConfig.suppressRowDeselection )
            ]

        createConfigAttribute ( key, value ) =
            Html.Attributes.attribute key (Json.Encode.encode 0 value)

        configAttributes =
            List.map createConfigAttribute encodedConfigValues
    in
    [ class (Maybe.withDefault "" gridConfig.themeClasses)
    , style "height" gridConfig.size
    ]
        ++ configAttributes


encodeExcelExportParams : ExcelExportParams -> Json.Encode.Value
encodeExcelExportParams params =
    Json.Encode.object
        [ ( "fileName", Json.Encode.string params.fileName )
        , ( "columnKeys", Json.Encode.list Json.Encode.string params.columnKeys )
        ]


encodeCsvExportParams : CsvExportParams -> Json.Encode.Value
encodeCsvExportParams params =
    Json.Encode.object
        [ ( "fileName", Json.Encode.string params.fileName )
        , ( "columnKeys", Json.Encode.list Json.Encode.string params.columnKeys )
        ]


encodeFilterButtonType : FilterButtonType -> Json.Encode.Value
encodeFilterButtonType filterButtonType =
    case filterButtonType of
        ApplyButton ->
            Json.Encode.string "apply"

        CancelButton ->
            Json.Encode.string "cancel"

        ClearButton ->
            Json.Encode.string "clear"

        ResetButton ->
            Json.Encode.string "reset"


encodeRowGroupPanelVisibility : RowGroupPanelVisibility -> Json.Encode.Value
encodeRowGroupPanelVisibility rowGroupPanelVisibility =
    case rowGroupPanelVisibility of
        AlwaysVisible ->
            Json.Encode.string "always"

        NeverVisible ->
            Json.Encode.string "never"

        OnlyWhenGroupingVisible ->
            Json.Encode.string "onlyWhenGrouping"


encodeSidebarType : SidebarType -> Json.Encode.Value
encodeSidebarType sidebarType =
    Json.Encode.string <|
        case sidebarType of
            ColumnSidebar ->
                "columns"

            FilterSidebar ->
                "filters"


rowEncoder : GridConfig dataType -> List (ColumnDef dataType) -> dataType -> Json.Encode.Value
rowEncoder gridConfig columns data =
    let
        rowCallbackValues =
            ( "rowCallbackValues", rowCallbackValuesEncoder gridConfig data )

        encodedAttributes =
            List.map (encoder data) columns
    in
    Json.Encode.object (rowCallbackValues :: encodedAttributes)


rowCallbackValuesEncoder : GridConfig dataType -> dataType -> Json.Encode.Value
rowCallbackValuesEncoder gridConfig data =
    Json.Encode.object
        [ ( "isRowSelectable", Json.Encode.bool (gridConfig.isRowSelectable data) )
        , ( "rowId"
          , case gridConfig.rowId of
                Just rowId ->
                    Json.Encode.string (rowId data)

                Nothing ->
                    Json.Encode.null
          )
        ]


encoder : dataType -> ColumnDef dataType -> ( String, Json.Encode.Value )
encoder data column =
    ( column.field
    , case column.renderer of
        AppRenderer _ valueGetter ->
            Json.Encode.string (valueGetter data)

        BoolRenderer valueGetter ->
            Json.Encode.bool (valueGetter data)

        CurrencyRenderer _ valueGetter ->
            encodeMaybe Json.Encode.string (valueGetter data)

        DateRenderer valueGetter ->
            Json.Encode.string (valueGetter data)

        DecimalRenderer _ valueGetter ->
            encodeMaybe Json.Encode.string (valueGetter data)

        FloatRenderer valueGetter ->
            Json.Encode.float (valueGetter data)

        GroupRenderer valueGetter ->
            Json.Encode.string (valueGetter data)

        IntRenderer valueGetter ->
            Json.Encode.int (valueGetter data)

        MaybeFloatRenderer valueGetter ->
            case valueGetter data of
                Just value ->
                    Json.Encode.float value

                Nothing ->
                    Json.Encode.null

        MaybeIntRenderer valueGetter ->
            case valueGetter data of
                Just value ->
                    Json.Encode.int value

                Nothing ->
                    Json.Encode.null

        MaybeStringRenderer valueGetter ->
            case valueGetter data of
                Just value ->
                    Json.Encode.string value

                Nothing ->
                    Json.Encode.null

        NoRenderer ->
            Json.Encode.null

        PercentRenderer _ valueGetter ->
            encodeMaybe Json.Encode.string (valueGetter data)

        SelectionRenderer valueGetter _ ->
            Json.Encode.string (valueGetter data)

        StringRenderer valueGetter ->
            Json.Encode.string (valueGetter data)
    )


encodeData : GridConfig dataType -> List (ColumnDef dataType) -> List dataType -> String
encodeData gridConfig columns data =
    if List.isEmpty data then
        Json.Encode.null |> Json.Encode.encode 0

    else
        data
            |> Json.Encode.list (rowEncoder gridConfig columns)
            |> Json.Encode.encode 0


cellUpdateDecoder : Decoder Decode.Value
cellUpdateDecoder =
    Decode.at [ "agGridDetails", "data" ] Decode.value


defaultColumnFilter : ColumnDef dataType -> ( FilterType, Maybe String )
defaultColumnFilter column =
    case column.renderer of
        AppRenderer _ _ ->
            ( NoFilter, Nothing )

        BoolRenderer _ ->
            ( SetFilter, Just (ValueFormat.booleanFilterValueGetter { field = column.field, true = "Yes", false = "No" }) )

        CurrencyRenderer _ _ ->
            ( NumberFilter, Just (ValueFormat.numberFilterValueGetter column.field) )

        DateRenderer _ ->
            ( DateFilter, Just (ValueFormat.dateFilterValueGetter column.field) )

        DecimalRenderer _ _ ->
            ( NumberFilter, Just (ValueFormat.numberFilterValueGetter column.field) )

        FloatRenderer _ ->
            ( NumberFilter, Just (ValueFormat.numberFilterValueGetter column.field) )

        GroupRenderer _ ->
            ( NoFilter, Nothing )

        IntRenderer _ ->
            ( NumberFilter, Just (ValueFormat.numberFilterValueGetter column.field) )

        MaybeFloatRenderer _ ->
            ( NumberFilter, Just (ValueFormat.numberFilterValueGetter column.field) )

        MaybeIntRenderer _ ->
            ( NumberFilter, Just (ValueFormat.numberFilterValueGetter column.field) )

        MaybeStringRenderer _ ->
            ( StringFilter, Nothing )

        NoRenderer ->
            ( NoFilter, Nothing )

        PercentRenderer _ _ ->
            ( NumberFilter, Just (ValueFormat.numberFilterValueGetter column.field) )

        SelectionRenderer _ _ ->
            ( SetFilter, Nothing )

        StringRenderer _ ->
            ( StringFilter, Nothing )


encodeFilterProperties : ColumnDef entity -> { encodedFilter : Json.Encode.Value, encodedFilterValueGetter : Json.Encode.Value }
encodeFilterProperties columnDef =
    let
        ( defaultFilter, defaultFilterValueFormatter ) =
            defaultColumnFilter columnDef

        encodeFilter filter =
            case filter of
                DefaultFilter ->
                    if defaultFilter == DefaultFilter then
                        -- This prevents the possible infinite loop
                        Json.Encode.null

                    else
                        encodeFilter defaultFilter

                DateFilter ->
                    Json.Encode.string "agDateColumnFilter"

                NumberFilter ->
                    Json.Encode.string "agNumberColumnFilter"

                StringFilter ->
                    Json.Encode.string "agTextColumnFilter"

                SetFilter ->
                    Json.Encode.string "agSetColumnFilter"

                NoFilter ->
                    Json.Encode.bool False
    in
    { encodedFilter = encodeFilter columnDef.settings.filter
    , encodedFilterValueGetter =
        columnDef.settings.filterValueGetter
            |> Maybe.map Just
            |> Maybe.withDefault defaultFilterValueFormatter
            |> encodeMaybe Json.Encode.string
    }


{-| Parse a string to a PinningType.

This can be used in combination with the value on the `ColumnState`.
Further, it can be used for external communication if necessary.

-}
toPinningType : Maybe String -> PinningType
toPinningType value =
    case value of
        Just "left" ->
            PinnedToLeft

        Just "right" ->
            PinnedToRight

        _ ->
            Unpinned


{-| Stringify a PinningType.

This matches the configuration for AgGrid and equals the value retrieved from the `ColumnState`.
Further, it can be used for external communication if necessary.

-}
pinningTypeToString : PinningType -> Maybe String
pinningTypeToString pinningType =
    case pinningType of
        PinnedToLeft ->
            Just "left"

        PinnedToRight ->
            Just "right"

        Unpinned ->
            Nothing


{-| Parse a string to an Aggregation.

This can be used in combination with the value on the `ColumnState`.
Further, it can be used for external communication if necessary.

-}
toAggregation : Maybe String -> Aggregation
toAggregation value =
    case value of
        Just "avg" ->
            AvgAggregation

        Just "count" ->
            CountAggregation

        Just "first" ->
            FirstAggregation

        Just "last" ->
            LastAggregation

        Just "max" ->
            MaxAggregation

        Just "min" ->
            MinAggregation

        Just "sum" ->
            SumAggregation

        Nothing ->
            NoAggregation

        Just aggFunc ->
            CustomAggregation aggFunc


{-| Stringify an Aggregation.

This matches the configuration for AgGrid and equals the value retrieved from the `ColumnState`.
Further, it can be used for external communication if necessary.

-}
aggregationToString : Aggregation -> Maybe String
aggregationToString aggregation =
    case aggregation of
        AvgAggregation ->
            Just "avg"

        CountAggregation ->
            Just "count"

        CustomAggregation name ->
            Just name

        FirstAggregation ->
            Just "first"

        LastAggregation ->
            Just "last"

        MaxAggregation ->
            Just "max"

        MinAggregation ->
            Just "min"

        NoAggregation ->
            Nothing

        SumAggregation ->
            Just "sum"


{-| Parse a string to the Sorting type.

This can be used in combination with the value on the `ColumnState`.
Further, it can be used for external communication if necessary.

-}
toSorting : Maybe String -> Sorting
toSorting value =
    case value of
        Just "asc" ->
            SortAscending

        Just "desc" ->
            SortDescending

        _ ->
            NoSorting


{-| Stringify the Sorting.

This matches the configuration for AgGrid and equals the value retrieved from the `ColumnState`.
Further, it can be used for external communication if necessary.

-}
sortingToString : Sorting -> Maybe String
sortingToString sorting =
    case sorting of
        SortAscending ->
            Just "asc"

        SortDescending ->
            Just "desc"

        NoSorting ->
            Nothing
