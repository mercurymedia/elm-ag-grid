module Main exposing (main)

import Aggregation
import Basic
import Browser exposing (Document)
import Browser.Navigation as Nav
import Css
import Css.Global
import Grouping
import Html.Styled exposing (Html, a, div, span, text)
import Html.Styled.Attributes exposing (css, href, target)
import RowSelection
import Url exposing (Url)
import Url.Parser as Parser



-- MAIN


main : Program () Model Msg
main =
    Browser.application
        { init = init
        , onUrlChange = ChangedUrl
        , onUrlRequest = ClickedLink
        , subscriptions = subscriptions
        , update = update
        , view = view
        }


type alias Model =
    { page : Page
    , navKey : Nav.Key
    }


type Page
    = Aggregation Aggregation.Model
    | Basic Basic.Model
    | Grouping Grouping.Model
    | RowSelection RowSelection.Model
    | NotFound


type Msg
    = ChangedUrl Url
    | ClickedLink Browser.UrlRequest
    | AggregationMsg Aggregation.Msg
    | BasicMsg Basic.Msg
    | RowSelectionMsg RowSelection.Msg
    | NoOp



-- MODEL


init : () -> Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url navKey =
    let
        initialModel =
            { page = NotFound, navKey = navKey }
    in
    changePageTo url initialModel



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.page of
        NotFound ->
            Sub.none

        Basic basicModel ->
            Sub.map BasicMsg (Basic.subscriptions basicModel)

        Aggregation aggregationModel ->
            Sub.map AggregationMsg (Aggregation.subscriptions aggregationModel)

        Grouping _ ->
            Sub.none

        RowSelection _ ->
            Sub.none



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model.page ) of
        ( ClickedLink urlRequest, _ ) ->
            case urlRequest of
                Browser.Internal url ->
                    ( model
                    , Nav.pushUrl model.navKey (Url.toString url)
                    )

                Browser.External href ->
                    ( model
                    , Nav.load href
                    )

        ( ChangedUrl url, _ ) ->
            changePageTo url model

        ( AggregationMsg subMsg, Aggregation aggregationModel ) ->
            let
                ( updatedAggregationModel, pageCmd ) =
                    Aggregation.update subMsg aggregationModel
            in
            ( { model | page = Aggregation updatedAggregationModel }, Cmd.map AggregationMsg pageCmd )

        ( BasicMsg subMsg, Basic basicModel ) ->
            let
                ( updatedBasicModel, pageCmd ) =
                    Basic.update subMsg basicModel
            in
            ( { model | page = Basic updatedBasicModel }, Cmd.map BasicMsg pageCmd )

        ( RowSelectionMsg subMsg, RowSelection rowSelectionModel ) ->
            let
                ( updatedRowSelectionModel, pageCmd ) =
                    RowSelection.update subMsg rowSelectionModel
            in
            ( { model | page = RowSelection updatedRowSelectionModel }, Cmd.map RowSelectionMsg pageCmd )

        ( NoOp, _ ) ->
            ( model, Cmd.none )

        ( _, _ ) ->
            ( model, Cmd.none )



-- VIEW


view : Model -> Document Msg
view model =
    { title = "elm-ag-grid"
    , body =
        [ Css.Global.global
            [ Css.Global.selector "body"
                [ Css.displayFlex
                , Css.margin (Css.px 0)
                , Css.height (Css.vh 100)
                , Css.overflow Css.hidden
                , Css.fontFamilies [ "Open Sans", "sans-serif" ]
                , Css.fontSize (Css.px 14)
                ]
            ]
        , viewSidebar
        , viewPage model.page
        ]
            |> List.map Html.Styled.toUnstyled
    }


viewSidebar : Html Msg
viewSidebar =
    div [ css [ Css.width (Css.px 200), Css.displayFlex, Css.flexDirection Css.column, Css.padding2 (Css.px 0) (Css.rem 2.5), Css.color (Css.hex "#555555") ] ]
        [ viewHeader
        , viewSources
        , viewNavigation
        ]


viewHeader : Html Msg
viewHeader =
    div [ css [ Css.marginTop (Css.rem 1), Css.fontSize (Css.rem 2.4) ] ] [ text "elm-ag-grid" ]


viewSources : Html Msg
viewSources =
    div [ css [ Css.displayFlex, Css.marginTop (Css.rem 2) ] ]
        [ a [ href "https://github.com/mercurymedia/elm-ag-grid", target "_blank", css [ Css.textDecoration Css.none, Css.cursor Css.pointer, Css.color (Css.hex "#177fd6") ] ] [ text "Github" ]
        , span [ css [ Css.padding2 (Css.px 0) (Css.px 8) ] ] [ text "|" ]
        , a [ href "https://package.elm-lang.org/packages/mercurymedia/elm-ag-grid/latest/", target "_blank", css [ Css.textDecoration Css.none, Css.cursor Css.pointer, Css.color (Css.hex "#177fd6") ] ] [ text "Docs" ]
        ]


viewNavigation : Html Msg
viewNavigation =
    div [ css [ Css.marginTop (Css.rem 2), Css.displayFlex, Css.flexDirection Css.column ] ]
        [ div [ css [ Css.color (Css.hex "#000000"), Css.fontWeight Css.normal ] ] [ text "Examples" ]
        , viewPageLink "Basic" "/"
        , viewPageLink "Aggregations & Formatting" "/aggregation"
        , viewPageLink "Grouping" "/grouping"
        , viewPageLink "RowSelection" "/row-selection"
        ]


viewPageLink : String -> String -> Html Msg
viewPageLink title url =
    a
        [ href url
        , css
            [ Css.textDecoration Css.none
            , Css.marginLeft (Css.px 15)
            , Css.cursor Css.pointer
            , Css.color (Css.hex "#177fd6")
            ]
        ]
        [ text title ]


viewPage : Page -> Html Msg
viewPage page =
    let
        toPage toMsg pageView =
            Html.Styled.map toMsg pageView
    in
    div [ css [ Css.flex (Css.px 0), Css.flexGrow (Css.num 1), Css.flexShrink (Css.num 0), Css.displayFlex, Css.backgroundColor (Css.hex "#f2f2f2") ] ]
        [ case page of
            NotFound ->
                text "Not found"

            Basic pageModel ->
                toPage BasicMsg (Basic.view pageModel)

            Aggregation pageModel ->
                toPage AggregationMsg (Aggregation.view pageModel)

            Grouping pageModel ->
                toPage (always NoOp) (Grouping.view pageModel)

            RowSelection pageModel ->
                toPage RowSelectionMsg (RowSelection.view pageModel)
        ]



-- HELPER


changePageTo : Url -> Model -> ( Model, Cmd Msg )
changePageTo url model =
    let
        toPage toModel toMsg ( pageModel, pageCmd ) =
            ( { model | page = toModel pageModel }, Cmd.map toMsg pageCmd )

        parser =
            Parser.oneOf
                [ Parser.map (Basic.init |> toPage Basic BasicMsg) Parser.top
                , Parser.map (Aggregation.init |> toPage Aggregation AggregationMsg) (Parser.s "aggregation")
                , Parser.map ( { model | page = Grouping Grouping.init }, Cmd.none ) (Parser.s "grouping")
                , Parser.map ( { model | page = RowSelection RowSelection.init }, Cmd.none ) (Parser.s "row-selection")
                ]
    in
    Parser.parse parser url
        |> Maybe.withDefault ( { model | page = NotFound }, Cmd.none )
