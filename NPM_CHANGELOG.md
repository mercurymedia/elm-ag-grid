# NPM Changelog

## [3.0.0]

- Added `isRowSelectable` callback to the GridOptions
- Changed: Updated `ag-grid-community` and `ag-grid-enterprise` peer-dependency to 29.1.0

## [2.1.0]

- Added new DecimalEditor component to edit localized cell values

## [2.0.0]

- BREAKING CHANGE: Updated `ag-grid-community` and `ag-grid-enterprise` peer-dependency to 29.0.0 and dropping support for versions before 29.0.0

## [1.3.0]

- Added `columnStateChanged` event to send table state changes to the Elm app

## [1.2.0]

- Added AgGrid's `autoHeight` usage when no `size` is set for the table (by default the table still uses `65vh`)

## [1.1.1]

- Updated README

## [1.1.0]

**Requires at least version 2.0.0 of the `elm-ag-grid` [Elm package](https://package.elm-lang.org/packages/mercurymedia/elm-ag-grid/2.0.0/).**

- Added cellRenderer to initialize elm applications and embed them into the cells
- Using `this` over `querySelector` in the webcomponent to allow multiple tables on the same page

## [1.0.1]

**Requires at least version 1.0.0 of the `elm-ag-grid` [Elm package](https://package.elm-lang.org/packages/mercurymedia/elm-ag-grid/1.0.1/).**

- Updated README
