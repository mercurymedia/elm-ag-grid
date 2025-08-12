module CustomEditor exposing (Model, init, view)

import AgGrid exposing (Renderer(..), defaultGridConfig, defaultSettings)
import AgGrid.Expression as Expression
import Components.Components as Components
import Components.Editor as Editor
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
        [ { infos = [], id = 1, country = "United States", sport = "Athletics", name = "Falkner Gregersen", year = 1995, prizeMoney = Just "1000.25" }
        , { infos = [], id = 2, country = "Russia", sport = "Swimming", name = "Arabel Beadle", year = 2007, prizeMoney = Just "2000.0" }
        , { infos = [], id = 3, country = "Russia", sport = "Gymnastics", name = "Aubrey Hulance", year = 2010, prizeMoney = Just "1500.5" }
        , { infos = [], id = 4, country = "Russia", sport = "Gymnastics", name = "Yetta Clooney", year = 1987, prizeMoney = Just "1800" }
        , { infos = [], id = 5, country = "France", sport = "Cycling", name = "Jake Langtree", year = 1997, prizeMoney = Just "2200.75" }
        , { infos = [], id = 6, country = "Russia", sport = "Athletics", name = "Verena Womersley", year = 1986, prizeMoney = Just "1700" }
        , { infos = [], id = 7, country = "United States", sport = "Gymnastics", name = "Chandler McEwen", year = 1994, prizeMoney = Just "1900.1234" }
        , { infos = [], id = 8, country = "United States", sport = "Gymnastics", name = "Shirlene Vasic", year = 1996, prizeMoney = Just "2100" }
        , { infos = [], id = 9, country = "France", sport = "Gymnastics", name = "Klarrisa Rosenfarb", year = 2004, prizeMoney = Just "2300.99" }
        , { infos = [], id = 10, country = "Germany", sport = "Gymnastics", name = "Peta Sallan", year = 2009, prizeMoney = Just "2500" }
        , { infos = [], id = 11, country = "Germany", sport = "Gymnastics", name = "Vaughn O'Hearn", year = 2005, prizeMoney = Just "2400.5" }
        , { infos = [], id = 12, country = "Germany", sport = "Gymnastics", name = "Jordana Gilliat", year = 2003, prizeMoney = Just "2600" }
        , { infos = [], id = 13, country = "France", sport = "Athletics", name = "Fidela Rodear", year = 1995, prizeMoney = Just "2700.333" }
        , { infos = [], id = 14, country = "France", sport = "Cycling", name = "Mirabelle Swinburne", year = 1986, prizeMoney = Just "2800" }
        , { infos = [], id = 15, country = "France", sport = "Swimming", name = "Sammy Bette", year = 2002, prizeMoney = Just "2900.75" }
        , { infos = [], id = 16, country = "United States", sport = "Cycling", name = "Bartolemo Jerg", year = 2003, prizeMoney = Just "3000" }
        , { infos = [], id = 17, country = "Russia", sport = "Cycling", name = "Crosby Kenworthey", year = 2011, prizeMoney = Just "3100.1" }
        , { infos = [], id = 18, country = "France", sport = "Swimming", name = "Sherlocke Woodland", year = 1989, prizeMoney = Just "3200" }
        , { infos = [], id = 19, country = "France", sport = "Fencing", name = "Kenton Mandrier", year = 1999, prizeMoney = Just "3300.4567" }
        , { infos = [], id = 20, country = "Russia", sport = "Swimming", name = "Porty Ornells", year = 1997, prizeMoney = Just "3400" }
        , { infos = [], id = 21, country = "Germany", sport = "Athletics", name = "Dolores Gribbell", year = 2008, prizeMoney = Just "3500.25" }
        , { infos = [], id = 22, country = "Russia", sport = "Fencing", name = "Alfi Hollingby", year = 2007, prizeMoney = Just "3600" }
        , { infos = [], id = 23, country = "Russia", sport = "Cycling", name = "Raeann Dessaur", year = 1989, prizeMoney = Just "3700.789" }
        , { infos = [], id = 24, country = "United States", sport = "Fencing", name = "Corenda Addicote", year = 1999, prizeMoney = Just "3800" }
        , { infos = [], id = 25, country = "Russia", sport = "Cycling", name = "Kynthia Gisby", year = 1985, prizeMoney = Just "3900.6543" }
        
        ]
    }



-- MODEL


type alias Model =
    { winners : List LineItem
    }


type alias LineItem =
    { infos : List String
    , id : Int
    , country : String
    , sport : String
    , name : String
    , year : Int
    , prizeMoney : Maybe String
    }



-- VIEW


view : Model -> Html msg
view model =
    Components.viewPage { headline = "CustomEditor", pageUrl = "https://github.com/mercurymedia/elm-ag-grid/blob/main/examples/src/CustomEditor.elm" }
        [ div [] [ text "The editor is usually derived from the defined Renderer. But the default editor that is associated with the renderer can also be overwritten. Either by using another existing editor (i.e. for the athlete) or using another Elm app to render the editor (i.e. for the info)." ]
        , viewGrid model
        ]


viewGrid : Model -> Html msg
viewGrid model =
    let
        gridConfig =
            { defaultGridConfig | themeClasses = Just "ag-theme-balham" }

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
                { field = "prizeMoney"
                , renderer = CurrencyRenderer { countryCode = "EUR", currency = "EUR", decimalPlaces = 4 } .prizeMoney
                , headerName = "Prize Money"
                , settings =  {defaultSettings | editable = Expression.Const True }
                }
            , AgGrid.Column
                { field = "info"
                , renderer = StringRenderer (.infos >> String.join ", ")
                , headerName = "Info"
                , settings = { defaultSettings | editable = Expression.Const True, customCellEditor = AgGrid.AppEditor Editor.config }
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
                , settings =
                    { defaultSettings
                        | editable = Expression.Const True
                        , customCellEditor =
                                (AgGrid.LargeTextEditor
                                    { maxLength = 500
                                    , rows = 10
                                    , cols = 50
                                    }
                                )
                    }
                }
            , AgGrid.Column
                { field = "sport"
                , renderer = StringRenderer .sport
                , headerName = "Sport"
                , settings = defaultSettings
                }
            ]
    in
    node "custom-editor-grid"
        [ css [ Css.display Css.block, Css.margin2 (Css.rem 1) (Css.px 0) ] ]
        [ AgGrid.grid gridConfig
            []
            columns
            model.winners
            |> Html.Styled.fromUnstyled
        ]
