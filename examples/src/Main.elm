module Main exposing (main)

import AgGrid exposing (Renderer(..))
import Browser
import Dict exposing (Dict)
import Html exposing (Html, div, input)
import Html.Attributes exposing (placeholder, style, value)
import Html.Events exposing (onInput)
import Json.Decode
import Result exposing (Result)



-- INIT


main : Program () Model Msg
main =
    Browser.element
        { init = \_ -> init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


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
              , favorite = False
              , id = 1
              , offerUntil = "01/01/2022"
              , price = 3
              , title = "Apple"
              }
            , { amountLeft = Just 15
              , category = Vegetable
              , description = Just "It's a pickle"
              , favorite = True
              , id = 2
              , offerUntil = "31/12/2022"
              , price = 2
              , title = "Cucumber"
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
    }



-- MODEL


type alias Model =
    { searchInput : String
    , products : Dict Int Product
    }


type Msg
    = UpdateSearchInput String
    | UpdateProduct (Result Json.Decode.Error Product)


type Category
    = Vegetable
    | Fruit


type alias Product =
    { amountLeft : Maybe Int
    , category : Category
    , description : Maybe String
    , favorite : Bool
    , id : Int
    , offerUntil : String
    , price : Int
    , title : String
    }



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
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



-- VIEW


view : Model -> Html Msg
view model =
    let
        gridConfig =
            AgGrid.defaultGridConfig
                |> (\config ->
                        { config
                            | sideBar = AgGrid.BothSidebars
                            , pagination = True
                            , quickFilterText = model.searchInput
                            , cacheQuickFilter = True
                            , themeClasses = Just "ag-theme-balham ag-basic"
                        }
                   )

        defaultSettings =
            AgGrid.defaultSettings
                |> (\settings -> { settings | editable = True })

        columns =
            [ { field = "id"
              , renderer = IntRenderer .id
              , headerName = "Id"
              , settings = { defaultSettings | hide = True }
              }
            , { field = "title"
              , renderer = StringRenderer .title
              , headerName = "Product"
              , settings = { defaultSettings | editable = False, pinned = AgGrid.PinnedToLeft }
              }
            , { field = "category"
              , renderer = SelectionRenderer (.category >> categoryToString) (List.map categoryToString [ Fruit, Vegetable ])
              , headerName = "Category"
              , settings = defaultSettings
              }
            , { field = "description"
              , renderer = MaybeStringRenderer .description
              , headerName = "Description"
              , settings = defaultSettings
              }
            , { field = "favorite"
              , renderer = BoolRenderer .favorite
              , headerName = "Favorite"
              , settings = defaultSettings
              }
            , { field = "offer-until"
              , renderer = StringRenderer .offerUntil
              , headerName = "Offer until"
              , settings = defaultSettings
              }
            , { field = "price"
              , renderer = IntRenderer .price
              , headerName = "Price"
              , settings = { defaultSettings | filter = AgGrid.NumberFilter }
              }
            , { field = "amount-left"
              , renderer = MaybeIntRenderer .amountLeft
              , headerName = "Amount Left"
              , settings = defaultSettings
              }
            ]
    in
    div []
        [ input
            [ value model.searchInput
            , onInput UpdateSearchInput
            , placeholder "Search ..."
            , style "margin-bottom" "8px"
            ]
            []
        , AgGrid.grid gridConfig [ AgGrid.onCellChanged rowDecoder UpdateProduct ] columns (Dict.values model.products)
        ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



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
    Json.Decode.map8 Product
        (Json.Decode.field "amount-left" (Json.Decode.nullable Json.Decode.int))
        (Json.Decode.field "category" (Json.Decode.string |> Json.Decode.andThen decodeCategory))
        (Json.Decode.field "description" (Json.Decode.nullable Json.Decode.string))
        (Json.Decode.field "favorite" Json.Decode.bool)
        (Json.Decode.field "id" Json.Decode.int)
        (Json.Decode.field "offer-until" Json.Decode.string)
        (Json.Decode.field "price" Json.Decode.int)
        (Json.Decode.field "title" Json.Decode.string)
