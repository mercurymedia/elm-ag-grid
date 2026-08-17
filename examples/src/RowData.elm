module RowData exposing (Model, Msg, init, update, view)

import AgGrid exposing (Renderer(..), RowDataColumns(..), defaultGridConfig, defaultSettings, defaultSidebar)
import AgGrid.Expression as Expression exposing (Eval(..))
import Components.Components as Components
import Css
import Dict exposing (Dict)
import Html.Styled exposing (Html, button, div, node, p, text)
import Html.Styled.Attributes exposing (css, disabled, type_)
import Html.Styled.Events exposing (onClick)



-- INIT


init : Model
init =
    { winners =
        [ { id = 1, country = "United States", sport = "Athletics", name = "Falkner Gregersen", year = 1995 }
        , { id = 2, country = "Russia", sport = "Swimming", name = "Arabel Beadle", year = 2007 }
        , { id = 3, country = "Russia", sport = "Gymnastics", name = "Aubrey Hulance", year = 2010 }
        , { id = 4, country = "Russia", sport = "Gymnastics", name = "Yetta Clooney", year = 1987 }
        , { id = 5, country = "France", sport = "Cycling", name = "Jake Langtree", year = 1997 }
        , { id = 6, country = "Russia", sport = "Athletics", name = "Verena Womersley", year = 1986 }
        , { id = 7, country = "United States", sport = "Gymnastics", name = "Chandler McEwen", year = 1994 }
        , { id = 8, country = "United States", sport = "Gymnastics", name = "Shirlene Vasic", year = 1996 }
        , { id = 9, country = "France", sport = "Gymnastics", name = "Klarrisa Rosenfarb", year = 2004 }
        , { id = 10, country = "Germany", sport = "Gymnastics", name = "Peta Sallan", year = 2009 }
        , { id = 11, country = "Germany", sport = "Gymnastics", name = "Vaughn O'Hearn", year = 2005 }
        , { id = 12, country = "Germany", sport = "Gymnastics", name = "Jordana Gilliat", year = 2003 }
        , { id = 13, country = "France", sport = "Athletics", name = "Fidela Rodear", year = 1995 }
        , { id = 14, country = "France", sport = "Cycling", name = "Mirabelle Swinburne", year = 1986 }
        , { id = 15, country = "France", sport = "Swimming", name = "Sammy Bette", year = 2002 }
        ]
    , columnStates = []
    , filterStates = Dict.empty
    , rowDataColumns = UsedColumns { alsoEncode = [] }
    }



-- MODEL


type alias Model =
    { winners : List LineItem
    , columnStates : List AgGrid.ColumnState
    , filterStates : Dict String AgGrid.FilterState
    , rowDataColumns : RowDataColumns
    }


type alias LineItem =
    { id : Int
    , country : String
    , sport : String
    , name : String
    , year : Int
    }


type Msg
    = ColumnStateChanged (AgGrid.StateChange (List AgGrid.ColumnState))
    | FilterStateChanged (AgGrid.StateChange (Dict String AgGrid.FilterState))
    | ChangedRowDataColumns RowDataColumns



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ColumnStateChanged { states } ->
            ( { model | columnStates = states }, Cmd.none )

        FilterStateChanged { states } ->
            ( { model | filterStates = states }, Cmd.none )

        ChangedRowDataColumns rowDataColumns ->
            ( { model | rowDataColumns = rowDataColumns }, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    Components.viewPage { headline = "RowData", pageUrl = "https://github.com/mercurymedia/elm-ag-grid/blob/main/examples/src/RowData.elm" }
        [ div [] <|
            List.map (p [] << List.singleton << text) <|
                [ "The rowData attribute carries one value per column and row and is re-encoded on every Elm render. On a grid with many columns that dominates the render cost, even though AgGrid only reads the columns it can actually reach."
                , "With \"rowDataColumns = UsedColumns\" only those columns are encoded: displayed, grouped, pivoted, aggregated, sorted, filtered, exported, or referenced by an expression. \"Country\" and \"Sport\" start out hidden and are left out entirely."
                , "\"Year\" is hidden as well, but a rowClassRule reads it to grey out everything before 1990 - so it is encoded regardless."
                , "Un-hide a column in the columns tool panel: AgGrid renders it before Elm has supplied the values, so its cells are empty for one frame. The column state event travels through update, the next render fills them in."
                , "The same holds for filtering a hidden column from the filters tool panel: the first application matches nothing until the filter state has reached the grid config."
                ]
        , viewModeSelector model.rowDataColumns
        , viewGrid model
        ]


viewModeSelector : RowDataColumns -> Html Msg
viewModeSelector current =
    div [ css [ Css.displayFlex, Css.marginTop (Css.px 8) ] ]
        [ viewModeButton current AllColumns "AllColumns"
        , viewModeButton current (UsedColumns { alsoEncode = [] }) "UsedColumns"
        ]


viewModeButton : RowDataColumns -> RowDataColumns -> String -> Html Msg
viewModeButton current mode label =
    button
        [ css [ Css.marginRight (Css.px 4) ]
        , type_ "button"
        , onClick (ChangedRowDataColumns mode)
        , disabled (current == mode)
        ]
        [ text label ]


viewGrid : Model -> Html Msg
viewGrid model =
    let
        gridConfig =
            { defaultGridConfig
                | themeClasses = Just "ag-theme-balham ag-basic"
                , size = "65vh"
                , sideBar =
                    { defaultSidebar
                        | panels = [ AgGrid.ColumnSidebar, AgGrid.FilterSidebar ]
                        , defaultToolPanel = Just AgGrid.ColumnSidebar
                    }
                , columnStates = model.columnStates
                , filterStates = model.filterStates
                , rowClassRules =
                    [ ( "ag-row-before-1990"
                      , Expr (Expression.lte (Expression.value "year") (Expression.int 1990))
                      )
                    ]
                , rowDataColumns = model.rowDataColumns
            }

        gridSettings =
            { defaultSettings | editable = Const False }

        columns =
            [ AgGrid.Column
                { field = "id"
                , renderer = IntRenderer .id
                , headerName = "ID"
                , settings = gridSettings
                }
            , AgGrid.Column
                { field = "name"
                , renderer = StringRenderer .name
                , headerName = "Name"
                , settings = gridSettings
                }
            , AgGrid.Column
                { field = "country"
                , renderer = StringRenderer .country
                , headerName = "Country"
                , settings = { gridSettings | hide = True }
                }
            , AgGrid.Column
                { field = "sport"
                , renderer = StringRenderer .sport
                , headerName = "Sport"
                , settings = { gridSettings | hide = True }
                }
            , AgGrid.Column
                { field = "year"
                , renderer = IntRenderer .year
                , headerName = "Year"
                , settings = { gridSettings | hide = True }
                }
            ]
    in
    node "rowdata-grid"
        [ css [ Css.display Css.block, Css.margin2 (Css.rem 1) (Css.px 0) ] ]
        [ AgGrid.grid gridConfig
            [ AgGrid.onColumnStateChanged ColumnStateChanged
            , AgGrid.onFilterStateChanged FilterStateChanged
            ]
            columns
            model.winners
            |> Html.Styled.fromUnstyled
        ]
