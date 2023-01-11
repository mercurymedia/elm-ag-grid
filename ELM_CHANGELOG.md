# Elm Changelog

## [3.2.0]

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
