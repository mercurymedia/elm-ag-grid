module AgGrid.Expression exposing
    ( Eval(..)
    , Expression
    , Literal
    , Operator
    , encode
    , eq
    , float
    , gte
    , int
    , lte
    , string
    , value
    , or 
    , and
    )

import Json.Encode as Encode


type Eval a
    = Const a
    | Expr Expression


type Expression
    = Value String
    | Lit Literal
    | Op Operator


type Literal
    = StringLiteral String
    | IntLiteral Int
    | FloatLiteral Float


type Operator
    = Or Expression Expression
    | And Expression Expression
    | Not Expression
    | Includes Expression Expression
    | Eq Expression Expression
    | Gte Expression Expression
    | Lte Expression Expression


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



-- Helper functions


value : String -> Expression
value accessor =
    Value accessor


or : Expression -> Expression -> Expression
or left right =
    Op (Or left right)


and : Expression -> Expression -> Expression
and left right =
    Op (And left right)


eq : Expression -> Expression -> Expression
eq left right =
    Op (Eq left right)


lte : Expression -> Expression -> Expression
lte left right =
    Op (Lte left right)


gte : Expression -> Expression -> Expression
gte left right =
    Op (Gte left right)


int : Int -> Expression
int i =
    Lit (IntLiteral i)


string : String -> Expression
string s =
    Lit (StringLiteral s)


float : Float -> Expression
float f =
    Lit (FloatLiteral f)
