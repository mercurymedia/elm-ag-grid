port module ColumnState exposing (Model, Msg, init, subscriptions, update, view)

import AgGrid exposing (Renderer(..), defaultGridConfig, defaultSettings, defaultSidebar)
import AgGrid.Expression as Expression exposing (Eval(..))
import Components.Components as Components
import Css
import Html.Styled exposing (Html, button, div, node, text)
import Html.Styled.Attributes exposing (css, disabled, type_)
import Html.Styled.Events exposing (onClick)
import Json.Decode as Decode
import Json.Encode as Encode
import Process
import RemoteData exposing (RemoteData)
import Task
import Time


port requestItem : String -> Cmd msg


port receivedItem : (( String, Encode.Value ) -> msg) -> Sub msg


port setItem : ( String, Encode.Value ) -> Cmd msg



-- INIT


init : ( Model, Cmd Msg )
init =
    ( initialModel
    , Cmd.batch
        [ requestItem (columnStorageKey initialModel.gridView)
        , Process.sleep 5000
            |> Task.andThen (\() -> Time.now)
            |> Task.perform GotTime
        ]
    )


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
    , gridView = ViewOne
    , columnStorage = RemoteData.Loading
    , time = Time.millisToPosix 0
    }



-- MODEL


type alias Model =
    { winners : List LineItem
    , gridView : View
    , columnStorage : RemoteData Decode.Error (List AgGrid.ColumnState)
    , time : Time.Posix
    }


type alias LineItem =
    { id : Int
    , country : String
    , sport : String
    , name : String
    , year : Int
    }


type View
    = ViewOne
    | ViewTwo


type Msg
    = ChangeView View
    | ColumnStateChanged (AgGrid.StateChange (List AgGrid.ColumnState))
    | GotColumnStorage (Result Decode.Error (List AgGrid.ColumnState))
    | GotTime Time.Posix
    | NoOp



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ChangeView gridView ->
            ( { model | gridView = gridView, columnStorage = RemoteData.Loading }, requestItem (columnStorageKey gridView) )

        ColumnStateChanged { states } ->
            ( { model | columnStorage = RemoteData.Success states }, setItem ( columnStorageKey model.gridView, AgGrid.columnStatesEncoder states ) )

        GotColumnStorage storage ->
            ( { model | columnStorage = RemoteData.fromResult storage }, Cmd.none )

        GotTime time ->
            ( { model | time = time }, Cmd.none )

        NoOp ->
            ( model, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    Components.viewPage { headline = "ColumnState", pageUrl = "https://github.com/mercurymedia/elm-ag-grid/blob/main/examples/src/ColumnState.elm" }
        [ div []
            [ [ "The column state listens for certain events in the Ag-Grid (e.g. onSortChanged, onColumnMoved, onGridColumnsChanged, onColumnResized, onColumnVisible) and populates the current column state into an event."
              , "This event can then be retrieved in Elm using \"onColumnStateChanged\". In addition, the state can be stored in external storage (e.g. Localstorage) and passed to the grid as \"columnStates\"."
              , "AgGrid then updates the columns (hide, pinning, sort, order, ...) of the grid according to the column states. The absence of the \"columnStates\" resets the columns according to the defined ColumnDefs."
              ]
                |> List.map String.trim
                |> String.join " "
                |> text
            ]
        , div [ css [ Css.marginTop (Css.rem 1) ] ]
            [ [ "It is worth mentioning that we also update the ColumnDefs passed to the AgGrid view according to the \"columnStates\" in the GridConfig."
              , "This is to ensure that updates to the ColumnDefs do not overwrite the \"columnState\"."
              , "If you actually want to overwrite the cached column state, you can do so by simply deleting the columnStates on the GridConfig. Any change listeners that persist column state to external storage are then automatically retriggered."
              ]
                |> List.map String.trim
                |> String.join " "
                |> text
            ]
        , viewViewSelector model.gridView
        , case model.columnStorage of
            RemoteData.Success storage ->
                viewGrid model.winners model.gridView model.time storage

            _ ->
                text ""
        ]


viewViewSelector : View -> Html Msg
viewViewSelector currentView =
    div [ css [ Css.displayFlex, Css.marginTop (Css.px 8) ] ]
        ([ ViewOne, ViewTwo ]
            |> List.map (viewChangeButton currentView)
        )


viewChangeButton : View -> View -> Html Msg
viewChangeButton currentView newView =
    button
        [ css [ Css.marginRight (Css.px 4) ]
        , type_ "button"
        , onClick (ChangeView newView)
        , disabled (currentView == newView)
        ]
        [ text <| viewToText newView
        ]


viewGrid : List LineItem -> View -> Time.Posix -> List AgGrid.ColumnState -> Html Msg
viewGrid winners gridView time columnStorage =
    let
        gridConfig =
            { defaultGridConfig
                | themeClasses = Just "ag-theme-balham ag-basic"
                , groupIncludeTotalFooter = True
                , size = "65vh"
                , sideBar = { defaultSidebar | panels = [ AgGrid.ColumnSidebar ], defaultToolPanel = Just AgGrid.ColumnSidebar }
                , columnStates = columnStorage
            }

        isViewTwo =
            gridView == ViewTwo

        gridSettings =
            { defaultSettings | hide = False, editable = Expression.Const False }

        columns =
            -- Lazy columns; columns change after receiving more data (in this example `time` is only added when available)
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
                , settings = { gridSettings | hide = not isViewTwo }
                }
            , AgGrid.Column
                { field = "sport"
                , renderer = StringRenderer .sport
                , headerName = "Sport"
                , settings = { gridSettings | hide = not isViewTwo }
                }
            , AgGrid.Column
                { field = "year"
                , renderer = IntRenderer .year
                , headerName = "Year"
                , settings = { gridSettings | hide = not isViewTwo }
                }
            ]
                ++ (if Time.posixToMillis time > 0 then
                        [ AgGrid.Column
                            { field = "POSIX time"
                            , renderer = IntRenderer (\_ -> Time.posixToMillis time)
                            , headerName = "POSIX time"
                            , settings = gridSettings
                            }
                        ]

                    else
                        []
                   )
    in
    node "aggregation-grid"
        [ css [ Css.display Css.block, Css.margin2 (Css.rem 1) (Css.px 0) ] ]
        [ AgGrid.grid gridConfig
            [ AgGrid.onColumnStateChanged ColumnStateChanged
            ]
            columns
            winners
            |> Html.Styled.fromUnstyled
        ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    receivedItem
        (\( key, value ) ->
            if key == columnStorageKey model.gridView then
                value
                    |> Decode.decodeValue AgGrid.columnStatesDecoder
                    |> GotColumnStorage

            else
                NoOp
        )



-- HELPER


columnStorageKey : View -> String
columnStorageKey gridView =
    case gridView of
        ViewOne ->
            "elm-ag-grid-column-state-view-one"

        ViewTwo ->
            "elm-ag-grid-column-state-view-two"


viewToText : View -> String
viewToText gridView =
    case gridView of
        ViewOne ->
            "View 1"

        ViewTwo ->
            "View 2"
