module AgGrid.Expression exposing (Eval(..), Expression(..), Literal(..), Operator(..), encode)

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
        Const value ->
            constEncoder value

        Expr expr ->
            encodeExpression expr


encodeExpression : Expression -> Encode.Value
encodeExpression expr =
    case expr of
        Lit value ->
            Encode.object
                [ ( "type", Encode.string "literal" )
                , ( "value", encodeLiteral value )
                ]

        Value value ->
            Encode.object
                [ ( "type", Encode.string "value" )
                , ( "value", Encode.string value )
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
        StringLiteral value ->
            Encode.string value

        IntLiteral value ->
            Encode.int value

        FloatLiteral value ->
            Encode.float value


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
