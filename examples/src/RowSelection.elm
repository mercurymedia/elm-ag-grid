module RowSelection exposing (Model, Msg, init, update, view)

import AgGrid exposing (Renderer(..), defaultGridConfig, defaultSettings)
import Components.Components as Components
import Css
import Html.Styled exposing (Html, button, div, node, text)
import Html.Styled.Attributes exposing (css)
import Html.Styled.Events exposing (onClick)
import Json.Decode as Decode exposing (Decoder)
import Set exposing (Set)



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
    , currentSelection = Set.empty
    }



-- MODEL


type alias Model =
    { winners : List LineItem
    , currentSelection : Set Int
    }


type alias LineItem =
    { id : Int
    , country : String
    , sport : String
    , name : String
    , year : Int
    }


type Msg
    = GotRowSelection (Result Decode.Error (List Int))
    | ResetSelection



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotRowSelection (Err err) ->
            ( model, Cmd.none )

        GotRowSelection (Ok selection) ->
            ( { model | currentSelection = Set.fromList selection }, Cmd.none )

        ResetSelection ->
            ( { model | currentSelection = Set.empty }, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    let
        selection =
            model.currentSelection
                |> Set.toList
                |> List.map String.fromInt
    in
    Components.viewPage { headline = "RowSelection", pageUrl = "https://github.com/mercurymedia/elm-ag-grid/blob/main/examples/src/RowSelection.elm" }
        [ div [] [ text "RowSelection" ]
        , viewGrid model selection
        , viewCurrentSelection selection
        ]


viewGrid : Model -> List String -> Html Msg
viewGrid model selection =
    let
        defaultAutoGroupColumnDef =
            defaultGridConfig.autoGroupColumnDef

        gridConfig =
            { defaultGridConfig
                | themeClasses = Just "ag-theme-balham"
                , rowSelection = AgGrid.MultipleRowSelection
                , groupDefaultExpanded = 1
                , groupSelectsChildren = True
                , selectedIds = selection
                , isRowSelectable = .year >> (<=) 2000
                , rowId = Just (.id >> String.fromInt)
                , autoGroupColumnDef =
                    { defaultAutoGroupColumnDef
                        | cellRendererParams =
                            { suppressCount = False
                            , checkbox = True
                            }
                    }
            }

        gridSettings =
            { defaultSettings | showDisabledCheckboxes = True }

        columns =
            [ { field = "id"
              , renderer = IntRenderer .id
              , headerName = "ID"
              , settings =
                    { gridSettings
                        | headerCheckboxSelection = True
                        , checkboxSelection = True
                        , lockPosition = AgGrid.LockToLeft
                    }
              }
            , { field = "country"
              , renderer = StringRenderer .country
              , headerName = "Country"
              , settings = { gridSettings | rowGroup = True }
              }
            , { field = "year"
              , renderer = IntRenderer .year
              , headerName = "Year"
              , settings = gridSettings
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
    node "row-selection-grid"
        [ css [ Css.display Css.block, Css.margin2 (Css.rem 1) (Css.px 0) ] ]
        [ AgGrid.grid gridConfig
            [ AgGrid.onSelectionChange selectionDecoder GotRowSelection ]
            columns
            model.winners
            |> Html.Styled.fromUnstyled
        ]


viewCurrentSelection : List String -> Html Msg
viewCurrentSelection selection =
    div []
        [ if List.isEmpty selection then
            text "No items selected"

          else
            div []
                [ div [] [ button [ onClick ResetSelection ] [ text "Deselect all" ] ]
                , div []
                    [ text ("Selected Items: " ++ String.join ", " selection)
                    ]
                ]
        ]



-- DECODER


selectionDecoder : Decoder Int
selectionDecoder =
    Decode.at [ "data", "id" ] Decode.int
