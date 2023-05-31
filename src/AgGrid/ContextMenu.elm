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


type alias ContextMenu =
    List ContextAction


type ContextAction
    = CustomItem ContextActionAttributes
    | PredefinedMenuItem String


type ChildContextAction
    = ChildContextAction ContextAction


type alias ContextActionAttributes =
    { name : String
    , checked : Maybe Bool
    , actionName : Maybe String
    , icon : Maybe String
    , disabled : Eval Bool
    , subMenu : List ChildContextAction
    }



-- Custom context actions


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


autoSizeAllContextAction : ContextAction
autoSizeAllContextAction =
    PredefinedMenuItem "autoSizeAll"


expandAllContextAction : ContextAction
expandAllContextAction =
    PredefinedMenuItem "expandAll"


contractAllContextAction : ContextAction
contractAllContextAction =
    PredefinedMenuItem "contractAll"


copyContextAction : ContextAction
copyContextAction =
    PredefinedMenuItem "copy"


copyWithHeadersContextAction : ContextAction
copyWithHeadersContextAction =
    PredefinedMenuItem "copyWithHeaders"


copyWithGroupHeadersContextAction : ContextAction
copyWithGroupHeadersContextAction =
    PredefinedMenuItem "copyWithGroupHeaders"


cutContextAction : ContextAction
cutContextAction =
    PredefinedMenuItem "cut"


pasteContextAction : ContextAction
pasteContextAction =
    PredefinedMenuItem "paste"


resetColumnsContextAction : ContextAction
resetColumnsContextAction =
    PredefinedMenuItem "resetColumns"


exportContextAction : ContextAction
exportContextAction =
    PredefinedMenuItem "export"


csvExportContextAction : ContextAction
csvExportContextAction =
    PredefinedMenuItem "csvExport"


excelExportContextAction : ContextAction
excelExportContextAction =
    PredefinedMenuItem "excelExport"


chartRangeContextAction : ContextAction
chartRangeContextAction =
    PredefinedMenuItem "chartRange"


pivotChartContextAction : ContextAction
pivotChartContextAction =
    PredefinedMenuItem "pivotChart"


contextSeparator : ContextAction
contextSeparator =
    PredefinedMenuItem "separator"



-- ENCODER


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
