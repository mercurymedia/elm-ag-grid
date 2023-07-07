module AgGrid.ContextMenu exposing
    ( ContextAction, ChildContextAction(..), ContextMenu
    , contextAction, defaultActionAttributes
    , autoSizeAllContextAction, chartRangeContextAction, contractAllContextAction, copyContextAction, copyWithGroupHeadersContextAction, copyWithHeadersContextAction
    , csvExportContextAction, cutContextAction, excelExportContextAction, expandAllContextAction, exportContextAction, pasteContextAction, pivotChartContextAction
    , resetColumnsContextAction, contextSeparator
    , encode
    )

{-|


# Definition

@docs ContextAction, ChildContextAction, ContextMenu


# Custom context action

@docs contextAction, defaultActionAttributes


# Predefined context actions

@docs autoSizeAllContextAction, chartRangeContextAction, contractAllContextAction, copyContextAction, copyWithGroupHeadersContextAction, copyWithHeadersContextAction
@docs csvExportContextAction, cutContextAction, excelExportContextAction, expandAllContextAction, exportContextAction, pasteContextAction, pivotChartContextAction
@docs resetColumnsContextAction, contextSeparator


# Encoding

@docs encode

-}

import AgGrid.Expression as Expression exposing (Eval(..))
import Json.Encode
import Json.Encode.Extra


{-| Type alias for a context menu.
-}
type alias ContextMenu =
    List ContextAction


{-| Context action configuration.
-}
type ContextAction
    = CustomItem ContextActionAttributes
    | PredefinedMenuItem String


{-| Child Context action configuration.
-}
type ChildContextAction
    = ChildContextAction ContextAction


{-| Context action attributes

This can be used to define a custom context action.

-}
type alias ContextActionAttributes =
    { name : String
    , checked : Maybe Bool
    , actionName : Maybe String
    , icon : Maybe String
    , disabled : Eval Bool
    , subMenu : List ChildContextAction
    }



-- Custom context actions


{-| Create a custom context action
-}
contextAction :
    { name : String
    , checked : Maybe Bool
    , actionName : Maybe String
    , disabled : Eval Bool
    , icon : Maybe String
    , subMenu : List ChildContextAction
    }
    -> ContextAction
contextAction config =
    CustomItem config


{-| Retrieves `ContextActionAttributes` with default configuration.

Can be used to ease the context action attributes configuration.

        { name = ""
        , checked = Nothing
        , disabled = Const False
        , actionName = Nothing
        , icon = Nothing
        , subMenu = []
        }

-}
defaultActionAttributes : ContextActionAttributes
defaultActionAttributes =
    { name = ""
    , checked = Nothing
    , disabled = Const False
    , actionName = Nothing
    , icon = Nothing
    , subMenu = []
    }



-- Predefined context actions


{-| Auto-size all columns.

Reference: <https://www.ag-grid.com/javascript-data-grid/context-menu/#built-in-menu-items>

-}
autoSizeAllContextAction : ContextAction
autoSizeAllContextAction =
    PredefinedMenuItem "autoSizeAll"


{-| When set, it's only shown if grouping by at least one column.

Reference: <https://www.ag-grid.com/javascript-data-grid/context-menu/#built-in-menu-items>

-}
expandAllContextAction : ContextAction
expandAllContextAction =
    PredefinedMenuItem "expandAll"


{-| Collapse all groups. When set, it's only shown if grouping by at least one column.

Reference: <https://www.ag-grid.com/javascript-data-grid/context-menu/#built-in-menu-items>

-}
contractAllContextAction : ContextAction
contractAllContextAction =
    PredefinedMenuItem "contractAll"


{-| Copy selected value to clipboard.

Reference: <https://www.ag-grid.com/javascript-data-grid/context-menu/#built-in-menu-items>

-}
copyContextAction : ContextAction
copyContextAction =
    PredefinedMenuItem "copy"


{-| Copy selected value to clipboard with headers.

Reference: <https://www.ag-grid.com/javascript-data-grid/context-menu/#built-in-menu-items>

-}
copyWithHeadersContextAction : ContextAction
copyWithHeadersContextAction =
    PredefinedMenuItem "copyWithHeaders"


{-| Copy selected value to clipboard with headers and header groups.

Reference: <https://www.ag-grid.com/javascript-data-grid/context-menu/#built-in-menu-items>

-}
copyWithGroupHeadersContextAction : ContextAction
copyWithGroupHeadersContextAction =
    PredefinedMenuItem "copyWithGroupHeaders"


{-| Cut the selected value to clipboard.

Reference: <https://www.ag-grid.com/javascript-data-grid/context-menu/#built-in-menu-items>

-}
cutContextAction : ContextAction
cutContextAction =
    PredefinedMenuItem "cut"


{-| Always disabled.

Reference: <https://www.ag-grid.com/javascript-data-grid/context-menu/#built-in-menu-items>

-}
pasteContextAction : ContextAction
pasteContextAction =
    PredefinedMenuItem "paste"


{-| Reset all columns

Reference: <https://www.ag-grid.com/javascript-data-grid/context-menu/#built-in-menu-items>

-}
resetColumnsContextAction : ContextAction
resetColumnsContextAction =
    PredefinedMenuItem "resetColumns"


{-| Export sub menu (containing csvExport and excelExport).

Reference: <https://www.ag-grid.com/javascript-data-grid/context-menu/#built-in-menu-items>

-}
exportContextAction : ContextAction
exportContextAction =
    PredefinedMenuItem "export"


{-| Export to CSV using all default export values.

Reference: <https://www.ag-grid.com/javascript-data-grid/context-menu/#built-in-menu-items>

-}
csvExportContextAction : ContextAction
csvExportContextAction =
    PredefinedMenuItem "csvExport"


{-| Export to Excel (.xlsx) using all default export values.

Reference: <https://www.ag-grid.com/javascript-data-grid/context-menu/#built-in-menu-items>

-}
excelExportContextAction : ContextAction
excelExportContextAction =
    PredefinedMenuItem "excelExport"


{-| Chart a range of selected cells. Only shown if charting is enabled.

Reference: <https://www.ag-grid.com/javascript-data-grid/context-menu/#built-in-menu-items>

-}
chartRangeContextAction : ContextAction
chartRangeContextAction =
    PredefinedMenuItem "chartRange"


{-| Chart all grouped and pivoted data from the grid. Only shown if charting is enabled and in Pivot Mode.

Reference: <https://www.ag-grid.com/javascript-data-grid/context-menu/#built-in-menu-items>

-}
pivotChartContextAction : ContextAction
pivotChartContextAction =
    PredefinedMenuItem "pivotChart"


{-| Adds a septerator to the context menu.

Reference: <https://www.ag-grid.com/javascript-data-grid/context-menu/#built-in-menu-items>

-}
contextSeparator : ContextAction
contextSeparator =
    PredefinedMenuItem "separator"



-- ENCODER


{-| Encodes the ContextMenu type to json.
-}
encode : ContextMenu -> Json.Encode.Value
encode contextMenu =
    Json.Encode.list encodeContextAction contextMenu


encodeContextAction : ContextAction -> Json.Encode.Value
encodeContextAction action =
    case action of
        CustomItem config ->
            encodeCustomContextAction config

        PredefinedMenuItem name ->
            Json.Encode.string name


encodeCustomContextAction : ContextActionAttributes -> Json.Encode.Value
encodeCustomContextAction action =
    Json.Encode.object
        [ ( "name", Json.Encode.string action.name )
        , ( "checked", Json.Encode.Extra.encodeMaybe Json.Encode.bool action.checked )
        , ( "actionName", Json.Encode.Extra.encodeMaybe Json.Encode.string action.actionName )
        , ( "disabledCallback", Expression.encode Json.Encode.bool action.disabled )
        , ( "icon", Json.Encode.Extra.encodeMaybe Json.Encode.string action.icon )
        , ( "subMenu", Json.Encode.list encodeSubMenuItem action.subMenu )
        ]


encodeSubMenuItem : ChildContextAction -> Json.Encode.Value
encodeSubMenuItem (ChildContextAction action) =
    encodeContextAction action
