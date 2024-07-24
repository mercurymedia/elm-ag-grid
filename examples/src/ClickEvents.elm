module ClickEvents exposing (Model, Msg, init, subscriptions, update, view)

import AgGrid exposing (FilterType(..), Renderer(..), defaultGridConfig, defaultSettings, defaultSidebar)
import AgGrid.Expression as Expression exposing (Eval(..))
import Components.Components as Components
import Css
import Html.Styled exposing (Html, div, node, p, text)
import Html.Styled.Attributes exposing (css)
import Json.Decode as Decode



-- INIT


init : ( Model, Cmd Msg )
init =
    ( initialModel
    , Cmd.none
    )


persons : List Person
persons =
    [ { birthday = "2220-03-22", ship = "USS Enterprise (NCC-1701)", age = 63, name = "James T. Kirk", isFullAge = True }
    , { birthday = "2336-07-13", ship = "USS Enterprise (NCC-1701-D)", age = 47, name = "Jean-Luc Picard", isFullAge = True }
    , { birthday = "2223-01-15", ship = "USS Voyager (NCC-74656)", age = 60, name = "Kathryn Janeway", isFullAge = True }
    , { birthday = "2230-03-22", ship = "USS Defiant (NX-74205)", age = 53, name = "Benjamin Sisko", isFullAge = True }
    , { birthday = "2228-12-05", ship = "USS Enterprise (NCC-1701)", age = 55, name = "Spock", isFullAge = True }
    , { birthday = "2245-07-26", ship = "USS Enterprise (NCC-1701)", age = 38, name = "Leonard McCoy", isFullAge = True }
    , { birthday = "2230-03-22", ship = "USS Voyager (NCC-74656)", age = 53, name = "Chakotay", isFullAge = True }
    , { birthday = "2340-12-02", ship = "USS Enterprise (NCC-1701-D)", age = 42, name = "William Riker", isFullAge = True }
    , { birthday = "2250-01-17", ship = "USS Defiant (NX-74205)", age = 43, name = "Jadzia Dax", isFullAge = True }
    , { birthday = "2329-02-16", ship = "USS Voyager (NCC-74656)", age = 50, name = "Tom Paris", isFullAge = True }
    , { birthday = "2233-03-22", ship = "USS Enterprise (NCC-1701)", age = 52, name = "Nyota Uhura", isFullAge = True }
    , { birthday = "2348-03-29", ship = "USS Enterprise (NCC-1701-D)", age = 34, name = "Data", isFullAge = True }
    , { birthday = "2249-02-22", ship = "USS Defiant (NX-74205)", age = 48, name = "Kira Nerys", isFullAge = True }
    , { birthday = "2261-11-17", ship = "USS Voyager (NCC-74656)", age = 40, name = "B'Elanna Torres", isFullAge = True }
    , { birthday = "2265-03-22", ship = "USS Enterprise (NCC-1701)", age = 56, name = "Montgomery Scott", isFullAge = True }
    , { birthday = "2335-08-29", ship = "USS Enterprise (NCC-1701-D)", age = 47, name = "Geordi La Forge", isFullAge = True }
    , { birthday = "2248-05-16", ship = "USS Defiant (NX-74205)", age = 49, name = "Miles O'Brien", isFullAge = True }
    , { birthday = "2255-08-19", ship = "USS Voyager (NCC-74656)", age = 47, name = "Harry Kim", isFullAge = True }
    , { birthday = "2239-03-22", ship = "USS Enterprise (NCC-1701)", age = 48, name = "Hikaru Sulu", isFullAge = True }
    , { birthday = "2264-01-14", ship = "USS Enterprise (NCC-1701)", age = 57, name = "Pavel Chekov", isFullAge = True }
    , { birthday = "2354-06-16", ship = "USS Enterprise (NCC-1701-D)", age = 38, name = "Worf", isFullAge = True }
    , { birthday = "2235-03-22", ship = "USS Defiant (NX-74205)", age = 48, name = "Ezri Dax", isFullAge = True }
    , { birthday = "2246-03-22", ship = "USS Voyager (NCC-74656)", age = 47, name = "Seven of Nine", isFullAge = True }
    , { birthday = "2285-03-22", ship = "USS Enterprise (NCC-1701)", age = 38, name = "Saavik", isFullAge = True }
    , { birthday = "2240-03-22", ship = "USS Enterprise (NCC-1701)", age = 48, name = "Christine Chapel", isFullAge = True }
    , { birthday = "2280-03-22", ship = "USS Defiant (NX-74205)", age = 43, name = "Julian Bashir", isFullAge = True }
    , { birthday = "2240-09-03", ship = "USS Voyager (NCC-74656)", age = 48, name = "Neelix", isFullAge = True }
    , { birthday = "2337-03-22", ship = "USS Enterprise (NCC-1701-D)", age = 46, name = "Deanna Troi", isFullAge = True }
    , { birthday = "2235-03-22", ship = "USS Voyager (NCC-74656)", age = 48, name = "The Doctor", isFullAge = True }
    , { birthday = "2249-03-22", ship = "USS Enterprise (NCC-1701)", age = 48, name = "Pavel Chekov", isFullAge = True }
    ]


initialModel : Model
initialModel =
    { lastClick = Nothing
    , lastDoubleClick = Nothing
    }



-- MODEL


type alias Model =
    { lastClick : Maybe ( Person, String )
    , lastDoubleClick : Maybe ( Person, String )
    }


type alias Person =
    { birthday : String
    , ship : String
    , age : Int
    , name : String
    , isFullAge : Bool
    }


type Msg
    = OnClick ( Result Decode.Error Person, String )
    | OnDoubleClick ( Result Decode.Error Person, String )



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        OnClick ( result, column ) ->
            ( { model | lastClick = Result.toMaybe result |> Maybe.map (\person -> ( person, column )) }, Cmd.none )

        OnDoubleClick ( result, column ) ->
            ( { model | lastDoubleClick = Result.toMaybe result |> Maybe.map (\person -> ( person, column )) }, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    let
        viewClick click =
            text <|
                case click of
                    Just ( person, column ) ->
                        case column of
                            "name" ->
                                person.name

                            "ship" ->
                                person.ship

                            "age" ->
                                person.age |> String.fromInt

                            _ ->
                                person.birthday

                    Nothing ->
                        "No click yet"
    in
    Components.viewPage { headline = "Click Events", pageUrl = "https://github.com/mercurymedia/elm-ag-grid/blob/main/examples/src/ClickEvents.elm" }
        [ p [] [ text "This example demonstrates listening for click events" ]
        , div [] [ text "Last Click: ", viewClick model.lastClick ]
        , div [] [ text "Last Double Click: ", viewClick model.lastDoubleClick ]
        , viewGrid
        ]


viewGrid : Html Msg
viewGrid =
    let
        gridConfig =
            { defaultGridConfig
                | themeClasses = Just "ag-theme-balham ag-basic"
                , groupIncludeTotalFooter = True
                , size = "65vh"
                , sideBar = { defaultSidebar | panels = [ AgGrid.ColumnSidebar ], defaultToolPanel = Just AgGrid.ColumnSidebar }
                , isRowSelectable = always False
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
            , AgGrid.Column
                { field = "full-age"
                , renderer = BoolRenderer .isFullAge
                , headerName = "Full age"
                , settings = { gridSettings | editable = Expression.Const True }
                }
            ]
    in
    node "filterstate-grid"
        [ css [ Css.display Css.block, Css.margin2 (Css.rem 1) (Css.px 0) ] ]
        [ AgGrid.grid gridConfig
            [ AgGrid.onCellDoubleClicked personDecoder OnDoubleClick
            , AgGrid.onCellClicked personDecoder OnClick
            ]
            columns
            persons
            |> Html.Styled.fromUnstyled
        ]


personDecoder : Decode.Decoder Person
personDecoder =
    Decode.map5 Person
        (Decode.field "name" Decode.string)
        (Decode.field "ship" Decode.string)
        (Decode.field "age" Decode.int)
        (Decode.field "birthday" Decode.string)
        (Decode.field "full-age" Decode.bool)



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none
