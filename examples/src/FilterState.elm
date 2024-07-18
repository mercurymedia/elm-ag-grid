port module FilterState exposing (Model, Msg, init, subscriptions, update, view)

import AgGrid exposing (FilterType(..), Renderer(..), defaultGridConfig, defaultSettings, defaultSidebar)
import AgGrid.Expression as Expression exposing (Eval(..))
import Components.Components as Components
import Css
import Dict exposing (Dict)
import Html.Styled exposing (Html, div, node, p, text)
import Html.Styled.Attributes exposing (css)
import Json.Decode as Decode
import Json.Encode as Encode
import RemoteData exposing (RemoteData)


port requestFilterState : () -> Cmd msg


port receivedFilterState : (Encode.Value -> msg) -> Sub msg


port setFilterState : Encode.Value -> Cmd msg



-- INIT


init : ( Model, Cmd Msg )
init =
    ( initialModel
    , Cmd.batch
        [ requestFilterState ()
        ]
    )


initialModel : Model
initialModel =
    { people =
        [ { birthday = "2220-03-22", ship = "USS Enterprise (NCC-1701)", age = 63, name = "James T. Kirk" }
        , { birthday = "2336-07-13", ship = "USS Enterprise (NCC-1701-D)", age = 47, name = "Jean-Luc Picard" }
        , { birthday = "2223-01-15", ship = "USS Voyager (NCC-74656)", age = 60, name = "Kathryn Janeway" }
        , { birthday = "2230-03-22", ship = "USS Defiant (NX-74205)", age = 53, name = "Benjamin Sisko" }
        , { birthday = "2228-12-05", ship = "USS Enterprise (NCC-1701)", age = 55, name = "Spock" }
        , { birthday = "2245-07-26", ship = "USS Enterprise (NCC-1701)", age = 38, name = "Leonard McCoy" }
        , { birthday = "2230-03-22", ship = "USS Voyager (NCC-74656)", age = 53, name = "Chakotay" }
        , { birthday = "2340-12-02", ship = "USS Enterprise (NCC-1701-D)", age = 42, name = "William Riker" }
        , { birthday = "2250-01-17", ship = "USS Defiant (NX-74205)", age = 43, name = "Jadzia Dax" }
        , { birthday = "2329-02-16", ship = "USS Voyager (NCC-74656)", age = 50, name = "Tom Paris" }
        , { birthday = "2233-03-22", ship = "USS Enterprise (NCC-1701)", age = 52, name = "Nyota Uhura" }
        , { birthday = "2348-03-29", ship = "USS Enterprise (NCC-1701-D)", age = 34, name = "Data" }
        , { birthday = "2249-02-22", ship = "USS Defiant (NX-74205)", age = 48, name = "Kira Nerys" }
        , { birthday = "2261-11-17", ship = "USS Voyager (NCC-74656)", age = 40, name = "B'Elanna Torres" }
        , { birthday = "2265-03-22", ship = "USS Enterprise (NCC-1701)", age = 56, name = "Montgomery Scott" }
        , { birthday = "2335-08-29", ship = "USS Enterprise (NCC-1701-D)", age = 47, name = "Geordi La Forge" }
        , { birthday = "2248-05-16", ship = "USS Defiant (NX-74205)", age = 49, name = "Miles O'Brien" }
        , { birthday = "2255-08-19", ship = "USS Voyager (NCC-74656)", age = 47, name = "Harry Kim" }
        , { birthday = "2239-03-22", ship = "USS Enterprise (NCC-1701)", age = 48, name = "Hikaru Sulu" }
        , { birthday = "2264-01-14", ship = "USS Enterprise (NCC-1701)", age = 57, name = "Pavel Chekov" }
        , { birthday = "2354-06-16", ship = "USS Enterprise (NCC-1701-D)", age = 38, name = "Worf" }
        , { birthday = "2235-03-22", ship = "USS Defiant (NX-74205)", age = 48, name = "Ezri Dax" }
        , { birthday = "2246-03-22", ship = "USS Voyager (NCC-74656)", age = 47, name = "Seven of Nine" }
        , { birthday = "2285-03-22", ship = "USS Enterprise (NCC-1701)", age = 38, name = "Saavik" }
        , { birthday = "2240-03-22", ship = "USS Enterprise (NCC-1701)", age = 48, name = "Christine Chapel" }
        , { birthday = "2280-03-22", ship = "USS Defiant (NX-74205)", age = 43, name = "Julian Bashir" }
        , { birthday = "2240-09-03", ship = "USS Voyager (NCC-74656)", age = 48, name = "Neelix" }
        , { birthday = "2337-03-22", ship = "USS Enterprise (NCC-1701-D)", age = 46, name = "Deanna Troi" }
        , { birthday = "2235-03-22", ship = "USS Voyager (NCC-74656)", age = 48, name = "The Doctor" }
        , { birthday = "2249-03-22", ship = "USS Enterprise (NCC-1701)", age = 48, name = "Pavel Chekov" }
        ]
    , filterState = RemoteData.Loading
    }



-- MODEL


type alias Model =
    { people : List Person
    , filterState : RemoteData Decode.Error (Dict String AgGrid.FilterState)
    }


type alias Person =
    { birthday : String
    , ship : String
    , age : Int
    , name : String
    }


type Msg
    = FilterStateChanged (AgGrid.StateChange (Dict String AgGrid.FilterState))
    | GotFilterState (Result Decode.Error (Dict String AgGrid.FilterState))
    | NoOp



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        FilterStateChanged { states } ->
            ( { model | filterState = RemoteData.Success states }, setFilterState (AgGrid.filterStatesEncoder states) )

        GotFilterState state ->
            ( { model | filterState = RemoteData.fromResult state }, Cmd.none )

        NoOp ->
            ( model, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    Components.viewPage { headline = "FilterState", pageUrl = "https://github.com/mercurymedia/elm-ag-grid/blob/main/examples/src/FilterState.elm" }
        [ div [] <|
            List.map (p [] << List.singleton << text) <|
                [ "The filter state listens for filterChanged events in the Ag-Grid "
                , "This event can then be retrieved in Elm using \"onFilterStateChanged\". In addition, the state can be stored in external storage (e.g. Localstorage) and passed to the grid as \"filterStates\"."
                , "AgGrid then updates the columns of the grid according to the filter states. The absence of the \"filterStates\" resets the columns according to the defined ColumnDefs."
                ]
        , case model.filterState of
            RemoteData.Success filterState ->
                viewGrid model.people filterState

            _ ->
                text ""
        ]


viewGrid : List Person -> Dict String AgGrid.FilterState -> Html Msg
viewGrid persons filterStates =
    let
        gridConfig =
            { defaultGridConfig
                | themeClasses = Just "ag-theme-balham ag-basic"
                , groupIncludeTotalFooter = True
                , size = "65vh"
                , sideBar = { defaultSidebar | panels = [ AgGrid.ColumnSidebar ], defaultToolPanel = Just AgGrid.ColumnSidebar }
                , filterStates = filterStates
            }

        gridSettings =
            { defaultSettings | editable = Expression.Const False }

        columns =
            [ AgGrid.Column
                { field = "name"
                , renderer = StringRenderer .name
                , headerName = "Name"
                , settings = gridSettings
                }
            , AgGrid.Column
                { field = "age"
                , renderer = IntRenderer .age
                , headerName = "Age"
                , settings = gridSettings
                }
            , AgGrid.Column
                { field = "ship"
                , renderer = StringRenderer .ship
                , headerName = "Ship"
                , settings = { gridSettings | filter = SetFilter }
                }
            , AgGrid.Column
                { field = "birthday"
                , renderer = DateRenderer .birthday
                , headerName = "Birthday"
                , settings = { gridSettings | filter = DateFilter }
                }
            ]
    in
    node "filterstate-grid"
        [ css [ Css.display Css.block, Css.margin2 (Css.rem 1) (Css.px 0) ] ]
        [ AgGrid.grid gridConfig
            [ AgGrid.onFilterStateChanged FilterStateChanged
            ]
            columns
            persons
            |> Html.Styled.fromUnstyled
        ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    receivedFilterState <| Decode.decodeValue AgGrid.filterStatesDecoder >> GotFilterState
