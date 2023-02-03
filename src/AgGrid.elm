module AgGrid exposing
    ( Aggregation(..), ColumnDef, FilterType(..), PinningType(..), Renderer(..), SidebarType(..), StateChange
    , GridConfig, grid
    , defaultGridConfig, defaultSettings
    , onCellChanged, onCellDoubleClicked
    , ColumnState, onColumnStateChanged, columnStatesDecoder, columnStatesEncoder
    , FilterState, onFilterStateChanged, filterStatesEncoder, filterStatesDecoder
    )

{-| AgGrid integration for elm.


# Data Types

@docs Aggregation, ColumnDef, FilterType, PinningType, Renderer, SidebarType, StateChange


# Grid

@docs GridConfig, grid


# Defaults

@docs defaultGridConfig, defaultSettings


# Events

@docs onCellChanged, onCellDoubleClicked


# ColumnState

@docs ColumnState, onColumnStateChanged, columnStatesDecoder, columnStatesEncoder


# FilterState

@docs FilterState, onFilterStateChanged, filterStatesEncoder, filterStatesDecoder

-}

import Dict
import Html exposing (Html, node)
import Html.Attributes exposing (attribute, class, id, style)
import Html.Events
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as DecodePipeline
import Json.Encode


{-| Variants to aggregate values for a grouped column.
-}
type Aggregation
    = AvgAggregation
    | CountAggregation
    | FirstAggregation
    | LastAggregation
    | MaxAggregation
    | MinAggregation
    | NoAggregation
    | SumAggregation


{-| Possible variants of callbacks that can lead to a certain change.
-}
type EventType
    = ColumnMoved
    | ColumnResized
    | FilterChanged
    | GridColumnsChanged
    | SortChanged


{-| Possible filter options for columns.
-}
type FilterType
    = NumberFilter
    | StringFilter
    | SetFilter
    | NoFilter


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
    | FloatRenderer (dataType -> Float)
    | GroupRenderer (dataType -> String)
    | IntRenderer (dataType -> Int)
    | MaybeFloatRenderer (dataType -> Maybe Float)
    | MaybeIntRenderer (dataType -> Maybe Int)
    | MaybeStringRenderer (dataType -> Maybe String)
    | NoRenderer
    | SelectionRenderer (dataType -> String) (List String)
    | StringRenderer (dataType -> String)


{-| Possible options for displayed sidebars.
-}
type SidebarType
    = BothSidebars
    | ColumnSidebar
    | FilterSidebar
    | NoSidebar


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
    , editable : Bool
    , enablePivot : Bool
    , enableRowGroup : Bool
    , enableValue : Bool
    , filter : FilterType
    , hide : Bool
    , minWidth : Maybe Int
    , pinned : PinningType
    , sortable : Bool
    , suppressColumnsToolPanel : Bool
    , suppressFiltersToolPanel : Bool
    , suppressMenu : Bool
    , suppressSizeToFit : Bool
    , valueFormatter : Maybe String
    , valueGetter : Maybe String
    , valueParser : Maybe String
    , valueSetter : Maybe String
    , width : Maybe Int
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
    , width : Int
    }


{-| Filter state.

Can be used to evaluate the current filter configuration whenever a filter on a column gets changed.

Might be used to persist the filters applied to the table for the users to the localstorage or some
other external storage. Filter states can be restored through the `filterState` on the `GridConfig`.

-}
type alias FilterState =
    { filterType : String
    , filter : Maybe String
    , type_ : Maybe String
    , values : List String
    }


{-| Grid configurations.
-}
type alias GridConfig =
    { allowColResize : Bool
    , autoSizeColumns : Bool
    , cacheQuickFilter : Bool
    , columnStates : List ColumnState
    , detailRenderer :
        Maybe
            { componentName : String
            , componentParams : Maybe Json.Encode.Value
            , rowHeight : Maybe Int
            }
    , disableResizeOnScroll : Bool
    , filterStates : Dict.Dict String FilterState
    , groupIncludeTotalFooter : Bool
    , pagination : Bool
    , quickFilterText : String
    , rowHeight : Maybe Int
    , sideBar : SidebarType
    , size : String
    , suppressMenuHide : Bool
    , themeClasses : Maybe String
    }


{-| Change event data for a table state changes.
-}
type alias StateChange type_ =
    { event : { type_ : EventType }
    , states : type_
    }



-- Defaults


{-| Retrieve a `ColumnSettings` record with default configuration.

Can be used when implementing column configurations for the table.

Default column settings:

    { editable = False
    , enablePivot = True
    , enableRowGroup = True
    , enableValue = True
    , filter = SetFilter
    , hide = False
    , pinned = Unpinned
    , sortable = True
    , suppressColumnsToolPanel = False
    , suppressFiltersToolPanel = False
    , suppressMenu = False
    , suppressSizeToFit = True
    , width = Nothing
    }

-}
defaultSettings : ColumnSettings
defaultSettings =
    { aggFunc = NoAggregation
    , editable = False
    , enablePivot = True
    , enableRowGroup = True
    , enableValue = True
    , filter = SetFilter
    , hide = False
    , minWidth = Nothing
    , pinned = Unpinned
    , sortable = True
    , suppressColumnsToolPanel = False
    , suppressFiltersToolPanel = False
    , suppressMenu = False
    , suppressSizeToFit = True
    , valueFormatter = Nothing
    , valueGetter = Nothing
    , valueParser = Nothing
    , valueSetter = Nothing
    , width = Nothing
    }


{-| Retrieve a `GridConfig` record with default configuration.

Can be used when implementing the grid.

        { allowColResize = True
        , autoSizeColumns = False
        , cacheQuickFilter = False
        , disableResizeOnScroll = False
        , pagination = False
        , rowHeight = Nothing
        , quickFilterText = ""
        , sideBar = NoSidebar
        , size = "65vh"
        , suppressMenuHide = False
        , themeClasses = Nothing
        }

-}
defaultGridConfig : GridConfig
defaultGridConfig =
    { allowColResize = True
    , autoSizeColumns = False
    , cacheQuickFilter = False
    , columnStates = []
    , detailRenderer = Nothing
    , disableResizeOnScroll = False
    , filterStates = Dict.empty
    , groupIncludeTotalFooter = False
    , pagination = False
    , quickFilterText = ""
    , rowHeight = Nothing
    , sideBar = NoSidebar
    , size = "65vh"
    , suppressMenuHide = False
    , themeClasses = Nothing
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
grid : GridConfig -> List (Html.Attribute msg) -> List (ColumnDef dataType) -> List dataType -> Html msg
grid gridConfig events columnDefs data =
    let
        columns =
            columnDefs
                |> prepareColumns gridConfig
                |> Json.Encode.list (columnDefEncoder gridConfig)
                |> Json.Encode.encode 0

        configAttributes =
            generateGridConfigAttributes gridConfig
    in
    node "ag-grid"
        ([ id "ag-grid"
         , attribute "columnDefs" columns
         , attribute "rowData" (encodeData columnDefs data)
         ]
            ++ configAttributes
            ++ events
        )
        []


prepareColumns : GridConfig -> List (ColumnDef dataType) -> List (ColumnDef dataType)
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



-- Encoding/Decoding


cellEditorParamsEncoder : CellEditorParams -> Json.Encode.Value
cellEditorParamsEncoder params =
    Json.Encode.object
        [ ( "values", Json.Encode.list Json.Encode.string params.values )
        ]


columnDefEncoder : GridConfig -> ColumnDef dataType -> Json.Encode.Value
columnDefEncoder gridConfig columnDef =
    Json.Encode.object
        [ ( "aggFunc"
          , case columnDef.settings.aggFunc of
                AvgAggregation ->
                    Json.Encode.string "avg"

                CountAggregation ->
                    Json.Encode.string "count"

                FirstAggregation ->
                    Json.Encode.string "first"

                LastAggregation ->
                    Json.Encode.string "last"

                MaxAggregation ->
                    Json.Encode.string "max"

                MinAggregation ->
                    Json.Encode.string "min"

                NoAggregation ->
                    Json.Encode.null

                SumAggregation ->
                    Json.Encode.string "sum"
          )
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
          , case columnDef.renderer of
                SelectionRenderer _ _ ->
                    Json.Encode.string "agRichSelectCellEditor"

                BoolRenderer _ ->
                    Json.Encode.string "booleanCellEditor"

                _ ->
                    Json.Encode.null
          )
        , ( "cellEditorParams"
          , case columnDef.renderer of
                SelectionRenderer _ collection ->
                    cellEditorParamsEncoder { values = collection }

                _ ->
                    Json.Encode.null
          )
        , ( "editable", Json.Encode.bool columnDef.settings.editable )
        , ( "enablePivot", Json.Encode.bool columnDef.settings.enablePivot )
        , ( "enableRowGroup", Json.Encode.bool columnDef.settings.enableRowGroup )
        , ( "enableValue", Json.Encode.bool columnDef.settings.enableValue )
        , ( "field", Json.Encode.string columnDef.field )
        , ( "filter"
          , case columnDef.settings.filter of
                NumberFilter ->
                    Json.Encode.string "agNumberColumnFilter"

                StringFilter ->
                    Json.Encode.string "agTextColumnFilter"

                SetFilter ->
                    Json.Encode.string "agSetColumnFilter"

                NoFilter ->
                    Json.Encode.bool False
          )
        , ( "headerName", Json.Encode.string columnDef.headerName )
        , ( "hide", Json.Encode.bool columnDef.settings.hide )
        , ( "minWidth", encodeMaybe Json.Encode.int columnDef.settings.minWidth )
        , ( "pinned"
          , case columnDef.settings.pinned of
                PinnedToLeft ->
                    Json.Encode.string "left"

                PinnedToRight ->
                    Json.Encode.string "right"

                Unpinned ->
                    Json.Encode.null
          )
        , ( "sortable", Json.Encode.bool columnDef.settings.sortable )
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
        , ( "valueFormatter", encodeMaybe Json.Encode.string columnDef.settings.valueFormatter )
        , ( "valueGetter", encodeMaybe Json.Encode.string columnDef.settings.valueGetter )
        , ( "valueParser", encodeMaybe Json.Encode.string columnDef.settings.valueParser )
        , ( "valueSetter", encodeMaybe Json.Encode.string columnDef.settings.valueSetter )
        , ( "width"
          , case columnDef.settings.width of
                Just width ->
                    Json.Encode.int width

                Nothing ->
                    Json.Encode.null
          )
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
        |> DecodePipeline.required "width" Decode.int


{-| Decoder for the current column states.

Can be used to retrieve and decode the column states from an external storage.

-}
columnStatesDecoder : Decoder (List ColumnState)
columnStatesDecoder =
    Decode.oneOf [ Decode.list columnStateDecoder, Decode.null [] ]


filterStateDecoder : Decoder FilterState
filterStateDecoder =
    Decode.succeed FilterState
        |> DecodePipeline.required "filterType" Decode.string
        |> DecodePipeline.optional "filter" (Decode.nullable Decode.string) Nothing
        |> DecodePipeline.optional "type" (Decode.nullable Decode.string) Nothing
        |> DecodePipeline.optional "values" (Decode.oneOf [ Decode.list Decode.string, Decode.null [] ]) []


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
        , ( "width", Json.Encode.int columnState.width )
        ]


{-| Encode a collection of `FilterState`.

Can be used to persist the current collection of `FilterState` for the grid to an external storage.

-}
filterStatesEncoder : Dict.Dict String FilterState -> Json.Encode.Value
filterStatesEncoder =
    Json.Encode.dict identity filterStateEncoder


filterStateEncoder : FilterState -> Json.Encode.Value
filterStateEncoder filterState =
    Json.Encode.object
        [ ( "filterType", Json.Encode.string filterState.filterType )
        , ( "filter", encodeMaybe Json.Encode.string filterState.filter )
        , ( "type", encodeMaybe Json.Encode.string filterState.type_ )
        , ( "values", Json.Encode.list Json.Encode.string filterState.values )
        ]


encodeMaybe : (a -> Json.Encode.Value) -> Maybe a -> Json.Encode.Value
encodeMaybe valueEncoder value =
    value
        |> Maybe.map valueEncoder
        |> Maybe.withDefault Json.Encode.null


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

                    "gridColumnsChanged" ->
                        Decode.succeed GridColumnsChanged

                    "sortChanged" ->
                        Decode.succeed SortChanged

                    "filterChanged" ->
                        Decode.succeed FilterChanged

                    unexpectedType ->
                        Decode.fail ("unexpected event type: " ++ unexpectedType)
            )


generateGridConfigAttributes : GridConfig -> List (Html.Attribute msg)
generateGridConfigAttributes gridConfig =
    let
        encodedConfigValues =
            [ ( "animateRows", Json.Encode.bool True )
            , ( "cacheQuickFilter", Json.Encode.bool gridConfig.cacheQuickFilter )
            , ( "columnState", columnStatesEncoder gridConfig.columnStates )
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
            , ( "filterState", filterStatesEncoder gridConfig.filterStates )
            , ( "headerHeight", Json.Encode.int 48 )
            , ( "quickFilterText"
              , if String.isEmpty gridConfig.quickFilterText then
                    Json.Encode.null

                else
                    Json.Encode.string gridConfig.quickFilterText
              )
            , ( "defaultColDef"
              , Json.Encode.object
                    [ ( "filter", Json.Encode.bool True )
                    , ( "enableValue", Json.Encode.bool True )
                    , ( "enableRowGroup", Json.Encode.bool True )
                    , ( "enablePivot", Json.Encode.bool True )
                    , ( "filterParams"
                      , Json.Encode.object
                            [ ( "buttons", Json.Encode.list Json.Encode.string [ "clear" ] )
                            ]
                      )
                    , ( "resizable", Json.Encode.bool gridConfig.allowColResize )
                    ]
              )
            , ( "disableResizeOnScroll", Json.Encode.bool gridConfig.disableResizeOnScroll )
            , ( "enableRangeSelection", Json.Encode.bool True )
            , ( "groupIncludeTotalFooter", Json.Encode.bool gridConfig.groupIncludeTotalFooter )
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
            , ( "sideBar"
              , case gridConfig.sideBar of
                    BothSidebars ->
                        Json.Encode.bool True

                    ColumnSidebar ->
                        Json.Encode.string "columns"

                    FilterSidebar ->
                        Json.Encode.string "filters"

                    NoSidebar ->
                        Json.Encode.bool False
              )
            , ( "sizeToFitAfterFirstDataRendered", Json.Encode.bool True )
            , ( "stopEditingWhenCellsLoseFocus", Json.Encode.bool True )
            , ( "suppressMenuHide", Json.Encode.bool gridConfig.suppressMenuHide )
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


rowEncoder : List (ColumnDef dataType) -> dataType -> Json.Encode.Value
rowEncoder columns data =
    let
        encoders =
            List.map (encoder data) columns
    in
    Json.Encode.object encoders


encoder : dataType -> ColumnDef dataType -> ( String, Json.Encode.Value )
encoder data column =
    ( column.field
    , case column.renderer of
        AppRenderer _ valueGetter ->
            Json.Encode.string (valueGetter data)

        BoolRenderer valueGetter ->
            Json.Encode.bool (valueGetter data)

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

        SelectionRenderer valueGetter _ ->
            Json.Encode.string (valueGetter data)

        StringRenderer valueGetter ->
            Json.Encode.string (valueGetter data)
    )


encodeData : List (ColumnDef dataType) -> List dataType -> String
encodeData columns data =
    if List.isEmpty data then
        Json.Encode.null |> Json.Encode.encode 0

    else
        data
            |> Json.Encode.list (rowEncoder columns)
            |> Json.Encode.encode 0


cellUpdateDecoder : Decoder Decode.Value
cellUpdateDecoder =
    Decode.at [ "agGridDetails", "data" ] Decode.value
