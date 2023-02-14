module Grouping exposing (Model, init, view)

import AgGrid exposing (Renderer(..), defaultGridConfig, defaultSettings, defaultSidebar)
import Css
import Html.Styled exposing (Html, a, div, node, span, text)
import Html.Styled.Attributes exposing (css, href, target)



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


view : Model -> Html ()
view model =
    div [ css [ Css.width (Css.pct 100), Css.margin2 (Css.rem 0) (Css.rem 1) ] ]
        [ div [ css [ Css.margin2 (Css.rem 1) (Css.px 0), Css.displayFlex, Css.alignItems Css.center ] ]
            [ span [ css [ Css.fontSize (Css.rem 1.8), Css.marginRight (Css.px 5) ] ] [ text "Grouping" ]
            , a [ href "https://github.com/mercurymedia/elm-ag-grid/blob/main/examples/src/Grouping.elm", target "_blank" ] [ text "[source]" ]
            ]
        , div [ css [] ]
            [ div [] [ text "Columns can be grouped programmatically by setting the rowGroup property on the ColumnSettings." ]
            , div [ css [ Css.marginTop (Css.rem 1) ] ] [ text "The appearance of the AutoGroupColumn can be changed to a certain extent if required. And it is also possible to define the levels of groups that are expanded by default." ]
            ]
        , viewGrid model
        ]


viewGrid : Model -> Html ()
viewGrid model =
    let
        gridConfig =
            { defaultGridConfig
                | themeClasses = Just "ag-theme-balham ag-basic"
                , size = "65vh"
                , groupDefaultExpanded = 1
                , sideBar = { defaultSidebar | panels = [ AgGrid.ColumnSidebar ], defaultToolPanel = Just AgGrid.ColumnSidebar }
                , autoGroupColumnDef =
                    { headerName = Just "Winners"
                    , minWidth = Just 250
                    , cellRendererParams =
                        { suppressCount = False
                        , checkbox = True
                        }
                    , resizable = True
                    }
                , rowGroupPanelShow = AgGrid.AlwaysVisible
            }

        gridSettings =
            defaultSettings

        columns =
            [ { field = "id"
              , renderer = IntRenderer .id
              , headerName = "ID"
              , settings = { gridSettings | hide = True }
              }
            , { field = "country"
              , renderer = StringRenderer .country
              , headerName = "Country"
              , settings = { gridSettings | rowGroup = True }
              }
            , { field = "year"
              , renderer = IntRenderer .year
              , headerName = "Year"
              , settings = { gridSettings | rowGroup = True, hide = True }
              }
            , { field = "name"
              , renderer = StringRenderer .name
              , headerName = "Athlete"
              , settings = gridSettings
              }
            , { field = "sport"
              , renderer = StringRenderer .sport
              , headerName = "Sport"
              , settings = gridSettings
              }
            ]
    in
    node "grouping-grid"
        [ css [ Css.display Css.block, Css.margin2 (Css.rem 1) (Css.px 0) ] ]
        [ AgGrid.grid gridConfig [] columns model.winners
            |> Html.Styled.fromUnstyled
        ]
