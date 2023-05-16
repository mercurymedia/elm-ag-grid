const apply = (data, expr) => {
    switch (expr.type) {
        case "operator":
            return applyOperator(data, expr.value, expr.body)

        case "value":
            return data[expr.value]

        case "literal":
            return expr.value

        default:
            throw new Error(`Not a valid expression type: ${expr.type}`)
    }
}


const applyOperator = (data, operator, body) => {
    switch (operator) {
        case "&&":
            return and(apply(data, body.left), apply(data, body.right))

        case "|| ":
            return or(apply(data, body.left), apply(data, body.right))

        case "==":
            return eq(apply(data, body.left), apply(data, body.right))

        case "!":
            return not(apply(data, body))

        case "includes":
            return includes(apply(data, body.left), apply(data, body.right))

        case "<=":
            return lte(apply(data, body.left), apply(data, body.right))

        case ">=":
            return gte(apply(data, body.left), apply(data, body.right))

        default:
            throw new Error(`Not a valid operator: ${operator}`)
    }

}


const or = (a, b) => a || b
const and = (a, b) => a && b
const eq = (a, b) => a == b
const not = a => !a
const includes = (a, xs) => Array.from(xs).includes(a)
const lte = (a, b) => a <= b
const gte = (a, b) => a >= b

export default { apply }
