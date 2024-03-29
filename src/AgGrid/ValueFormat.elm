module AgGrid.ValueFormat exposing
    ( currencyValueFormatter, decimalValueFormatter, percentValueFormatter
    , numberValueGetter
    , booleanFilterValueGetter, numberFilterValueGetter, dateFilterValueGetter
    )

{-| Formatting of values in the AgGrid table.

Allows to format values as currencies, decimal, and percent.


# valueFormatter

@docs currencyValueFormatter, decimalValueFormatter, percentValueFormatter


# ValueGetter

@docs numberValueGetter


# filterValueGetter

@docs booleanFilterValueGetter, numberFilterValueGetter, dateFilterValueGetter

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

        return new Intl.NumberFormat('{0}', { style: 'percent', maximumFractionDigits: {1} }).format(value / 100)
    """ [ countryCode, String.fromInt decimalPlaces ]



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


{-| Format a cell value as number.

This is similar to using a normal Value Getter, but is specific to the filter.

    cellValue = "15"

    numberFilterValueGetter "numberField"
    > 15

-}
numberFilterValueGetter : String -> String
numberFilterValueGetter field =
    String.Interpolate.interpolate """
        if (!data.{0}) { return null; }

        return Number(data.{0})
    """ [ field ]


{-| Format a cell value as Date.

This is similar to using a normal Value Getter, but is specific to the filter.

    cellValue = "2023-12-12"

    dateFilterValueGetter "dateField"
    > const date = Date("2023-12-12");
    > date.setHours(0,0,0);

-}
dateFilterValueGetter : String -> String
dateFilterValueGetter field =
    String.Interpolate.interpolate """
        if (!data.{0}) { return null; }

        const date = new Date(data.{0});
        date.setHours(0,0,0);
        return date;
    """ [ field ]


{-| Format a boolean cell value with a proper translation.

This is similar to using a normal Value Getter, but is specific to the filter.

    cellValue = true

    booleanFilterValueGetter "boolField"
    > "Yes"

-}
booleanFilterValueGetter : { true : String, false : String, field : String } -> String
booleanFilterValueGetter { true, false, field } =
    String.Interpolate.interpolate """
        return data.{2} ? '{0}' : '{1}'
    """ [ true, false, field ]
