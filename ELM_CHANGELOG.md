# Elm Changelog

## [5.0.0]

- Changed the `Renderer` type by adding a new `CurrencyRenderer`, `DecimalRenderer`, and `PercentRenderer` to format cell values into localized strings
- Added `aggFunc` as column settings to define an Aggregation (Average, Sum, Min, Max, ...) for the column values.
- Further, added column settings options for `filterValueGetter`, `minWidth`, `valueGetter`, `valueFormatter`, `valueParser`, and `valueSetter`
- Added `groupIncludeFooter` and `groupIncludeTotalFooter` to the GridConfig, allowing to display a footer with aggregated values

## [4.0.0]

- Added a new `GroupRenderer` for grouping rows, allowing usage of MasterDetail
- Added a `detailRenderer` to the `GridConfig` to render a row's detailed view

## [3.1.0]

- Added a new `ColumnState`/`FilterState` type (as well as events, decoder, and encoder) to evaluate or persist table states to an external storage
- Added a `columnState` and `filterState` attribute to the `GridConfig` to apply a certain table state (order of columns, sorting, etc.) that might have been persisted externally before

## [3.0.0]

**Requires at least version 1.1.0 of the `elm-ag-grid` [NPM package](https://www.npmjs.com/package/@mercurymedia/elm-ag-grid/v/1.1.0).**

- Added new renderer type to render `Float` and `Maybe Float` values into cells (AgGrid cellRenderer)

## [2.0.0]

**Requires at least version 1.1.0 of the `elm-ag-grid` [NPM package](https://www.npmjs.com/package/@mercurymedia/elm-ag-grid/v/1.1.0).**

- Added new renderer type to render custom Elm views into the cells (AgGrid cellRenderer)
