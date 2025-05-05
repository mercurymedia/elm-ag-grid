port module Basic exposing (Model, Msg, init, subscriptions, update, view)

import AgGrid exposing (Renderer(..), defaultGridConfig, defaultSettings, defaultSidebar)
import AgGrid.Expression as Expression
import Components.Components as Components
import Css
import Css.Global
import Dict exposing (Dict)
import Html.Styled exposing (Html, div, input, text)
import Html.Styled.Attributes exposing (css, placeholder, style, value)
import Html.Styled.Events exposing (onInput)
import Json.Decode
import Json.Decode.Pipeline as DecodePipeline
import Json.Encode
import Result exposing (Result)
import String.Interpolate


port buttonClicked : (Int -> msg) -> Sub msg



-- INIT


init : ( Model, Cmd Msg )
init =
    ( initialModel, Cmd.none )


initialModel : Model
initialModel =
    let
        -- List of the same two elements repeated several times
        -- to create a representable long lists for the AgGrid table.
        products =
            [ { amountLeft = Nothing
              , category = Fruit
              , description = Nothing
              , detailsUrl = "#/apple"
              , favorite = False
              , id = 1
              , offerUntil = "01/01/2022"
              , price = 3.2
              , title = "Apple"
              , runtime = "1/02/2025 + 1/02/2026, 1/02/2027 + 1/02/2028"
              }
            , { amountLeft = Just 15
              , category = Vegetable
              , description = Just "It's a pickle"
              , favorite = True
              , id = 2
              , offerUntil = "31/12/2022"
              , price = 2.5
              , title = "Cucumber"
              , detailsUrl = "#/cucumber"
              , runtime = "5/02/2025 + 5/02/2026, 1/02/2027 + 5/02/2028"
              }
            ]
                |> List.repeat 150
                |> List.concat
                -- Provide unique index to simplify table updates
                |> List.indexedMap (\index product -> ( index, { product | id = index } ))
                |> Dict.fromList
    in
    { searchInput = ""
    , products = products
    , variant = "variant-1"
    }



-- MODEL


type alias Model =
    { searchInput : String
    , products : Dict Int Product
    , variant : String
    }


type Msg
    = NoOp
    | UpdateSearchInput String
    | UpdateProduct (Result Json.Decode.Error Product)
    | ClickedCellButton Int


type Category
    = Vegetable
    | Fruit


type alias Product =
    { amountLeft : Maybe Int
    , category : Category
    , description : Maybe String
    , detailsUrl : String
    , favorite : Bool
    , id : Int
    , offerUntil : String
    , runtime : String
    , price : Float
    , title : String
    }



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        UpdateSearchInput newSearchValue ->
            ( { model | searchInput = newSearchValue }, Cmd.none )

        UpdateProduct (Ok updatedProduct) ->
            let
                updatedProducts =
                    Dict.update updatedProduct.id (always (Just updatedProduct)) model.products
            in
            ( { model | products = updatedProducts }, Cmd.none )

        UpdateProduct (Err _) ->
            ( model, Cmd.none )

        ClickedCellButton _ ->
            let
                updatedVariant =
                    case model.variant of
                        "variant-1" ->
                            "variant-2"

                        _ ->
                            "variant-1"
            in
            ( { model | variant = updatedVariant }, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    Components.viewPage { headline = "Basic Grid", pageUrl = "https://github.com/mercurymedia/elm-ag-grid/blob/main/examples/src/Basic.elm" }
        [ div [] [ text "Basic grid example display various CellRenderer for different data types (Strings, Integers, Boolean, Floats, Selection, Maybe values)." ]
        , div [] [ text "Also displays the possibility to search, sort, pin columns, and rendering Elm apps into cells for a custom view that also communicate with the Main app." ]
        , viewGrid model
        ]


dateRangeFilterValueGetter : String -> String
dateRangeFilterValueGetter field =
    String.Interpolate.interpolate """
        if (!data.{0}) { return null; }
        const rawDataString = data.{0};
            
                if (!rawDataString) {
                    return null;
                }
            
                return rawDataString.split(',')
                    .map(dateRange => dateRange.split(' + ')
                        .map(dateString => {
                            const date = new Date(dateString.trim());
                            date.setHours(0, 0, 0, 0);
                            return date;
                        })
                    );
    
    """ [ field ]


viewGrid : Model -> Html Msg
viewGrid model =
    let
        gridConfig =
            { defaultGridConfig
                | sideBar = { defaultSidebar | panels = [ AgGrid.ColumnSidebar, AgGrid.FilterSidebar ] }
                , pagination = True
                , quickFilterText = model.searchInput
                , cacheQuickFilter = True
                , rowClassRules = [ ( "apple", Expression.Expr isApple ) ]
                , themeClasses = Just "ag-theme-balham ag-basic"
            }

        gridSettings =
            { defaultSettings | editable = Expression.Const True }

        isApple =
            Expression.eq (Expression.value "title") (Expression.string "Apple")

        isFruit =
            Expression.eq (Expression.value "category") (Expression.string "Fruit")

        isDiscounted =
            Expression.lte (Expression.value "price") (Expression.int 3)

        columns =
            [ AgGrid.Column
                { field = "id"
                , renderer = IntRenderer .id
                , headerName = "Id"
                , settings = { gridSettings | hide = True }
                }
            , AgGrid.Column
                { field = "title"
                , renderer = StringRenderer .title
                , headerName = "Product"
                , settings = { gridSettings | editable = Expression.Const False, pinned = AgGrid.PinnedToLeft }
                }
            , AgGrid.Column
                { field = "details"
                , renderer = AppRenderer { componentName = "linkRenderer", componentParams = Nothing } encodeDetails
                , headerName = "Details"
                , settings = { gridSettings | editable = Expression.Const False }
                }
            , AgGrid.Column
                { field = "detailsUrl"
                , renderer = StringRenderer .detailsUrl
                , headerName = ""
                , settings = { gridSettings | hide = True }
                }
            , AgGrid.Column
                { field = "category"
                , renderer = SelectionRenderer (.category >> categoryToString) (List.map categoryToString [ Fruit, Vegetable ])
                , headerName = "Category"
                , settings = gridSettings
                }
            , AgGrid.Column
                { field = "description"
                , renderer = MaybeStringRenderer .description
                , headerName = "Description"
                , settings = { gridSettings | editable = Expression.Expr isFruit }
                }
            , AgGrid.Column
                { field = "favorite"
                , renderer = BoolRenderer .favorite
                , headerName = "Favorite"
                , settings = gridSettings
                }
            , AgGrid.Column
                { field = "offer-until"
                , renderer = StringRenderer .offerUntil
                , headerName = "Offer until"
                , settings = gridSettings
                }
            , AgGrid.Column
                { field = "runtime"
                , renderer = StringRenderer .runtime
                , headerName = "Runtime"
                , settings = { gridSettings | filter = AgGrid.DateRangeFilter, filterValueGetter = Just (dateRangeFilterValueGetter "runtime") }
                }
            , AgGrid.ColumnGroup
                { headerName = "Prices"
                , children =
                    [ AgGrid.Column
                        { field = "price"
                        , renderer = FloatRenderer .price
                        , headerName = "Price"
                        , settings =
                            { gridSettings
                                | cellClassRules =
                                    [ ( "discount", Expression.Expr isDiscounted )
                                    , ( "high-price", Expression.Expr <| Expression.not isDiscounted )
                                    ]
                                , filter = AgGrid.NumberFilter
                            }
                        }
                    , AgGrid.Column
                        { field = "amount-left"
                        , renderer = MaybeIntRenderer .amountLeft
                        , headerName = "Amount Left"
                        , settings = gridSettings
                        }
                    ]
                }
            , AgGrid.Column
                { field = "table-button-column"
                , renderer = AppRenderer (buttonConfig model) (always "")
                , headerName = ""
                , settings = { gridSettings | editable = Expression.Const False }
                }
            ]
    in
    div
        [ css
            [ Css.Global.descendants
                [ Css.Global.class "discount" [ Css.important (Css.backgroundColor (Css.hex "3cb371")) ]
                , Css.Global.class "high-price" [ Css.backgroundColor (Css.hex "ff6347") ]
                , Css.Global.class "apple" [ Css.backgroundColor (Css.hex "fca5a5") ]
                ]
            , Css.margin2 (Css.rem 1) (Css.px 0)
            ]
        ]
        [ input
            [ value model.searchInput
            , onInput UpdateSearchInput
            , placeholder "Search ..."
            , style "margin-bottom" "8px"
            ]
            []
        , AgGrid.grid gridConfig
            [ AgGrid.onCellChanged rowDecoder UpdateProduct

            -- Eventlistener is not attached. Communication happens through ports.
            -- , onCellClicked ClickedCellButton
            ]
            columns
            (Dict.values model.products)
            |> Html.Styled.fromUnstyled
        ]


encodeDetails : Product -> String
encodeDetails product =
    Json.Encode.object
        [ ( "url", Json.Encode.string product.detailsUrl )
        , ( "linkName", Json.Encode.string product.title )
        ]
        |> Json.Encode.encode 0


buttonConfig : Model -> { componentName : String, componentParams : Maybe Json.Encode.Value }
buttonConfig model =
    let
        params =
            Json.Encode.object
                [ ( "variant", Json.Encode.string model.variant )
                ]
    in
    { componentName = "buttonRenderer"
    , componentParams = Just params
    }


{-| Possible event listener for button click events.

Attempts to read the Product Id of from the the clicked element ID that has
a format of `button-123`.

It's probably easiert to just use ports for communication with the components,
as this doesn't require to listen for all click events, filtering them, and
parsing a potential ID from a string.

The port provides more accuracy to only receive a message event when the actual
element was clicked and allows to send information much easier.

-}
onCellClicked : (Int -> Msg) -> Html.Styled.Attribute Msg
onCellClicked toMsg =
    let
        parseElementId elementId =
            case String.split "-" elementId of
                _ :: idString :: _ ->
                    String.toInt idString

                _ ->
                    Nothing

        valueDecoder =
            Json.Decode.at [ "target", "id" ] Json.Decode.string
                |> Json.Decode.andThen
                    (\elementId ->
                        case parseElementId elementId of
                            Just id ->
                                Json.Decode.succeed id

                            Nothing ->
                                Json.Decode.fail "invalid value"
                    )
                |> Json.Decode.map toMsg
    in
    Html.Styled.Events.on "click" valueDecoder



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    buttonClicked ClickedCellButton



-- HELPER


categoryToString : Category -> String
categoryToString category =
    case category of
        Fruit ->
            "Fruit"

        Vegetable ->
            "Vegetable"


decodeCategory : String -> Json.Decode.Decoder Category
decodeCategory categoryString =
    case categoryString of
        "Fruit" ->
            Json.Decode.succeed Fruit

        "Vegetable" ->
            Json.Decode.succeed Vegetable

        _ ->
            Json.Decode.fail "Failed decoding category"


rowDecoder : Json.Decode.Decoder Product
rowDecoder =
    Json.Decode.succeed Product
        |> DecodePipeline.required "amount-left" (Json.Decode.nullable Json.Decode.int)
        |> DecodePipeline.required "category" (Json.Decode.string |> Json.Decode.andThen decodeCategory)
        |> DecodePipeline.required "description" (Json.Decode.nullable Json.Decode.string)
        |> DecodePipeline.required "detailsUrl" Json.Decode.string
        |> DecodePipeline.required "favorite" Json.Decode.bool
        |> DecodePipeline.required "id" Json.Decode.int
        |> DecodePipeline.required "offer-until" Json.Decode.string
        |> DecodePipeline.required "runtime" Json.Decode.string
        |> DecodePipeline.required "price"
            (Json.Decode.oneOf
                [ Json.Decode.float
                , Json.Decode.map (String.toFloat >> Maybe.withDefault 0) Json.Decode.string
                ]
            )
        |> DecodePipeline.required "title" Json.Decode.string
