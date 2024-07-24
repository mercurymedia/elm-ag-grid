module Export exposing (Model, init, view)

import AgGrid exposing (Renderer(..), defaultGridConfig, defaultSettings)
import AgGrid.ContextMenu as ContextMenu
import Components.Components as Components
import Css
import Html.Styled exposing (Html, div, node, text)
import Html.Styled.Attributes exposing (css)



-- INIT


init : Model
init =
    initialModel


initialModel : Model
initialModel =
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
        , { id = 16, country = "United States", sport = "Cycling", name = "Bartolemo Jerg", year = 2003 }
        , { id = 17, country = "Russia", sport = "Cycling", name = "Crosby Kenworthey", year = 2011 }
        , { id = 18, country = "France", sport = "Swimming", name = "Sherlocke Woodland", year = 1989 }
        , { id = 19, country = "France", sport = "Fencing", name = "Kenton Mandrier", year = 1999 }
        , { id = 20, country = "Russia", sport = "Swimming", name = "Porty Ornells", year = 1997 }
        , { id = 21, country = "Germany", sport = "Athletics", name = "Dolores Gribbell", year = 2008 }
        , { id = 22, country = "Russia", sport = "Fencing", name = "Alfi Hollingby", year = 2007 }
        , { id = 23, country = "Russia", sport = "Cycling", name = "Raeann Dessaur", year = 1989 }
        , { id = 24, country = "United States", sport = "Fencing", name = "Corenda Addicote", year = 1999 }
        , { id = 25, country = "Russia", sport = "Cycling", name = "Kynthia Gisby", year = 1985 }
        ]
    }



-- MODEL


type alias Model =
    { winners : List LineItem
    }


type alias LineItem =
    { id : Int
    , country : String
    , sport : String
    , name : String
    , year : Int
    }



-- VIEW


view : Model -> Html msg
view model =
    Components.viewPage { headline = "Export", pageUrl = "https://github.com/mercurymedia/elm-ag-grid/blob/main/examples/src/Export.elm" }
        [ div [] [ text "Excel & CSV Export" ]
        , viewGrid model
        ]


viewGrid : Model -> Html msg
viewGrid model =
    let
        gridConfig =
            { defaultGridConfig
                | themeClasses = Just "ag-theme-balham"
                , excelExport = Just { fileName = "excel_example_export.xlsx", columnKeys = [ "country", "year", "name", "sport" ] }
                , csvExport = Just { fileName = "csv_example_export.csv", columnKeys = [ "country", "year", "name", "sport" ] }
                , contextMenu = Just [ ContextMenu.excelExportContextAction, ContextMenu.csvExportContextAction ]
            }

        columns =
            [ AgGrid.Column
                { field = "id"
                , renderer = IntRenderer .id
                , headerName = "ID"
                , settings = defaultSettings
                }
            , AgGrid.Column
                { field = "country"
                , renderer = StringRenderer .country
                , headerName = "Country"
                , settings = defaultSettings
                }
            , AgGrid.Column
                { field = "year"
                , renderer = IntRenderer .year
                , headerName = "Year"
                , settings = defaultSettings
                }
            , AgGrid.Column
                { field = "name"
                , renderer = StringRenderer .name
                , headerName = "Athlete"
                , settings = defaultSettings
                }
            , AgGrid.Column
                { field = "sport"
                , renderer = StringRenderer .sport
                , headerName = "Sport"
                , settings = defaultSettings
                }
            ]
    in
    node "export-grid"
        [ css [ Css.display Css.block, Css.margin2 (Css.rem 1) (Css.px 0) ] ]
        [ AgGrid.grid gridConfig [] columns model.winners
            |> Html.Styled.fromUnstyled
        ]
