module AgGrid.ValueFormat exposing
    ( currencyValueFormatter, decimalValueFormatter, percentValueFormatter
    , numberValueGetter
    , currencyFilterValueGetter, decimalFilterValueGetter, percentFilterValueGetter
    )

{-| Formatting of values in the AgGrid table.

Allows to format values as currencies, decimal, and percent.


# valueFormatter

@docs currencyValueFormatter, decimalValueFormatter, percentValueFormatter


# ValueGetter

@docs numberValueGetter


# filterValueGetter

@docs currencyFilterValueGetter, decimalFilterValueGetter, percentFilterValueGetter

-}

import String.Interpolate



-- VALUE FORMATTER


{-| Format a cell value as localized CURRENCY value utilizing the Javascript `Intl.NumberFormat` class.

    cellValue = "1200.35"

    currencyValueFormatter { currency = "EUR", countryCode = "de-DE" }
    > "1.200,35 €"

    currencyValueFormatter { currency = "EUR", countryCode = "en-US" }
    > "€1,200.35"

-}
currencyValueFormatter : { currency : String, countryCode : String } -> String
currencyValueFormatter { currency, countryCode } =
    String.Interpolate.interpolate """
        let input;

        if (value === null || value === undefined) { return null; }

        if (typeof value === 'object' && value.hasOwnProperty('value')) {
            // Group value
            input = value.value
        } else {
            // Cell value
            input = value
        }

        if (input === null || input === undefined) { return null; }

        return new Intl.NumberFormat('{0}', { style: 'currency', currency: '{1}' }).format(input)
    """ [ countryCode, currency ]


{-| Format a cell value as localized DECIMAL value utilizing the Javascript `Intl.NumberFormat` class.

    cellValue = 1200.35

    decimalValueFormatter { countryCode = "de-DE", decimalPlaces = 1 }
    > "1.200,4"

    decimalValueFormatter { countryCode = "en-US", decimalPlaces = 0 }
    > "1,200"

-}
decimalValueFormatter : { countryCode : String, decimalPlaces : Int } -> String
decimalValueFormatter { countryCode, decimalPlaces } =
    String.Interpolate.interpolate """
        let input;

        if (value === null || value === undefined) { return null; }

        if (typeof value === 'object' && value.hasOwnProperty('value')) {
            // Group value
            input = value.value
        } else {
            // Cell value
            input = value
        }

        if (input === null || input === undefined) { return null; }

        return new Intl.NumberFormat('{0}', { style: 'decimal', maximumFractionDigits: '{1}' }).format(value)
    """ [ countryCode, String.fromInt decimalPlaces ]


{-| Format a cell value as localized PERCENT value utilizing the Javascript `Intl.NumberFormat` class.

    cellValue = 0.15

    percentValueFormatter { countryCode = "de-DE" }
    > "15%"

-}
percentValueFormatter : { countryCode : String, decimalPlaces : Int } -> String
percentValueFormatter { countryCode, decimalPlaces } =
    String.Interpolate.interpolate """
        let input;

        if (value === null || value === undefined) { return null; }

        if (typeof value === 'object' && value.hasOwnProperty('value')) {
            // Group value
            input = value.value
        } else {
            // Cell value
            input = value
        }

        if (input === null || input === undefined) { return null; }

        return new Intl.NumberFormat('{0}', { style: 'percent', maximumFractionDigits: {1} }).format(value)
    """ [ countryCode, String.fromInt <| Basics.max (decimalPlaces - 2) 0 ]



-- VALUE GETTER


{-| Casts the field value as a number.

This is important if the cell value is given as a string (e.g. for currencies) but needs to a number
in order to aggregate the values.

-}
numberValueGetter : String -> String
numberValueGetter fieldName =
    String.Interpolate.interpolate """
    if (!data || !data.{0}) { return null; }

    return Number(data.{0})
    """ [ fieldName ]



-- FILTER VALUE FORMATTER


{-| Format a filter value as localized CURRENCY value utilizing the Javascript `Intl.NumberFormat` class.

    price = "1200.35"

    currencyFilterValueGetter { currency = "EUR", countryCode = "de-DE", field = "price" }
    > "1.200,35 €"

    currencyFilterValueGetter { currency = "EUR", countryCode = "en-US", field = "price" }
    > "€1,200.35"

-}
currencyFilterValueGetter : { currency : String, countryCode : String, field : String } -> String
currencyFilterValueGetter { currency, countryCode, field } =
    String.Interpolate.interpolate """
        if (!data.{2}) { return null; }

        return new Intl.NumberFormat('{0}', { style: 'currency', currency: '{1}' }).format(data.{2})
    """ [ countryCode, currency, field ]


{-| Format a filter value as localized DECIMAL value utilizing the Javascript `Intl.NumberFormat` class.

    volume = 1200.35

    decimalFilterValueGetter { countryCode = "de-DE", decimalPlaces = 1, field = "volume" }
    > "1.200,4"

    decimalFilterValueGetter { countryCode = "en-US", decimalPlaces = 0, field = "volume" }
    > "1,200"

-}
decimalFilterValueGetter : { countryCode : String, decimalPlaces : Int, field : String } -> String
decimalFilterValueGetter { countryCode, decimalPlaces, field } =
    String.Interpolate.interpolate """
        if (!data.{2}) { return null; }

        return new Intl.NumberFormat('{0}', { style: 'decimal', maximumFractionDigits: '{1}' }).format(data.{2})
    """ [ countryCode, String.fromInt decimalPlaces, field ]


{-| Format a filter value as localized PERCENT value utilizing the Javascript `Intl.NumberFormat` class.

    discount = 0.15

    percentFilterValueGetter { countryCode = "de-DE", field = "discount" }
    > "15%"

-}
percentFilterValueGetter : { countryCode : String, field : String } -> String
percentFilterValueGetter { countryCode, field } =
    String.Interpolate.interpolate """
        if (!data.{1}) { return null; }

        return new Intl.NumberFormat('{0}', { style: 'percent' }).format(data.{1})
    """ [ countryCode, field ]
