module AgGrid.Expression exposing
    ( Eval(..), Expression, Literal, Operator
    , or, and, eq, lte, gte, includes
    , int, string, float
    , encode
    , value
    )

{-| Integration of Expressions for AgGrid. A `Expression` will be encoded and evaluated in javascript.

For more information take a look at <https://github.com/mercurymedia/elm-ag-grid/blob/10.0.0/ag-grid-webcomponent/expression.js>.


# Definition

@docs Eval, Expression, Literal, Operator


# Operators

@docs or, and, eq, lte, gte, includes


# Literals

@docs int, string, float

# Row values

@docs value

# Encoding

@docs encode

-}

import Json.Encode as Encode


{-| `Eval a` can be a `Cosnt a` or and `Expr`
    
    A `Const a` will pass the value of the type `a` directly to the `AgGrid` attribute in javascript.
    A `Expr` will frist evaluated in javascript and than passed to the `AgGrid` attribute.

-}
type Eval a
    = Const a
    | Expr Expression


{-| A `Expression` covers some basic operators to evaluate

At this moment this only covers very basic operations

-}
type Expression
    = Value String
    | Lit Literal
    | Op Operator


{-| The `Literal` type represents literals for strings, ints and floats.
-}
type Literal
    = StringLiteral String
    | IntLiteral Int
    | FloatLiteral Float


{-| A `Operator` takes two expressions and evaluate the result in javascript.
-}
type Operator
    = Or Expression Expression
    | And Expression Expression
    | Not Expression
    | Includes Expression Expression
    | Eq Expression Expression
    | Gte Expression Expression
    | Lte Expression Expression


{-| The encode encodes a evaluation.
-}
encode : (a -> Encode.Value) -> Eval a -> Encode.Value
encode constEncoder eval =
    case eval of
        Const const ->
            constEncoder const

        Expr expr ->
            encodeExpression expr


encodeExpression : Expression -> Encode.Value
encodeExpression expr =
    case expr of
        Lit literal ->
            Encode.object
                [ ( "type", Encode.string "literal" )
                , ( "value", encodeLiteral literal )
                ]

        Value v ->
            Encode.object
                [ ( "type", Encode.string "value" )
                , ( "value", Encode.string v )
                ]

        Op operator ->
            Encode.object
                [ ( "type", Encode.string "operator" )
                , ( "value", Encode.string (operatorToString operator) )
                , ( "body", encodeOperator operator )
                ]


encodeOperator : Operator -> Encode.Value
encodeOperator operator =
    case operator of
        Or left right ->
            Encode.object
                [ ( "left", encodeExpression left ), ( "right", encodeExpression right ) ]

        And left right ->
            Encode.object
                [ ( "left", encodeExpression left ), ( "right", encodeExpression right ) ]

        Eq left right ->
            Encode.object
                [ ( "left", encodeExpression left ), ( "right", encodeExpression right ) ]

        Includes left right ->
            Encode.object
                [ ( "left", encodeExpression left ), ( "right", encodeExpression right ) ]

        Gte left right ->
            Encode.object
                [ ( "left", encodeExpression left ), ( "right", encodeExpression right ) ]

        Lte left right ->
            Encode.object
                [ ( "left", encodeExpression left ), ( "right", encodeExpression right ) ]

        Not expr ->
            encodeExpression expr


encodeLiteral : Literal -> Encode.Value
encodeLiteral literal =
    case literal of
        StringLiteral s ->
            Encode.string s

        IntLiteral i ->
            Encode.int i

        FloatLiteral f ->
            Encode.float f


operatorToString : Operator -> String
operatorToString operator =
    case operator of
        Or _ _ ->
            "||"

        And _ _ ->
            "&&"

        Eq _ _ ->
            "=="

        Includes _ _ ->
            "includes"

        Not _ ->
            "!"

        Gte _ _ ->
            ">="

        Lte _ _ ->
            "<="



-- Utility functions


{-| The value function can be used to get a value from the data object passed in from a callback of `AgGrid`.

For example when it comes to disable a contextMenu entry, you can get a value from the current clicked row.

    type alias Row =
        { age : Int }

    columnDefs =
        [ { field = "age"
          , renderer = IntRenderer .age
          , headerName = "Age"
          , settings = AgGrid.defaultSettings
          }
        ]

    contextMenu =
        [ AgGridContextMenu.contextAction
            { defaultActionAttributes
                | name = "Full age action"
                , actionName = Just "fullAgeAction"
                , disabled = Expression.Expr (Expression.lte (Expression.value "age") (Expression.int 18))
            }
        ]

-}
value : String -> Expression
value accessor =
    Value accessor


{-| Represents the || operator

    Expression.or (Expression.value "likesElm") (Expression.value "isProgrammer")

-}
or : Expression -> Expression -> Expression
or left right =
    Op (Or left right)


{-| Represents the && operator

    Expression.and (Expression.value "likesElm") (Expression.value "isProgrammer")

-}
and : Expression -> Expression -> Expression
and left right =
    Op (And left right)


{-| Represents the == operator

    Expression.eq (Expression.int 18) (Expression.value "age")

-}
eq : Expression -> Expression -> Expression
eq left right =
    Op (Eq left right)


{-| Represents the <= operator

    Expression.lte (Expression.int 18) (Expression.value "age")

-}
lte : Expression -> Expression -> Expression
lte left right =
    Op (Lte left right)


{-| Represents the >= operator

    Expression.gte (Expression.int 18) (Expression.value "age")

-}
gte : Expression -> Expression -> Expression
gte left right =
    Op (Gte left right)


{-| Performs the javascript Array.inclues function

    Expression.includes (Expression.string "Tim") (Expression.value "names")
    Where names is a list of Strings.

-}
includes : Expression -> Expression -> Expression
includes left right =
    Op (Includes left right)


{-| A int Literal

    Expression.int 18

-}
int : Int -> Expression
int i =
    Lit (IntLiteral i)


{-| A string Literal

    Expression.string "Tim"

-}
string : String -> Expression
string s =
    Lit (StringLiteral s)


{-| A string Literal

    Expression.string 13.37

-}
float : Float -> Expression
float f =
    Lit (FloatLiteral f)
