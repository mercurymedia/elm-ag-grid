# Elm Changelog

## [14.1.0]

- Added `bool` and `list` literal for expressions.

## [14.0.0]

- Added `customCellEditor` attribute on `ColumnSettings`. This allows to alter the cell editor used for the column.
- Added `csvExport` and `excelExport` on `GridConfig`. This allows to configure the export capabilities for the grid.

## [13.0.0]

- Changed `cellClassRules` attribute on `ColumnSettings`. The values are now provided as tuple, more similarly to `classList`, where the first value
  is the class and the second value is the condition (as `Expression` type). This provides more consistency using the same kind of expression throughout
  the code and allows to reuse the expressions on different attributes.

## [12.0.0]

- Added `cellClassRules` to `ColumnSettings`
- Changed `editable` from a boolean to an expression (default will be `Expression.Const False`)

## [11.0.0]

- Add `autoHeaderHeight` and `wrapHeaderText` to `ColumnSettings`

## [10.2.0]

- Exposing `not` operator utility function from `AgGrid.Expression`

## [10.1.0]

- Exposing `AgGrid.ContextMenu` module.
- Exposing `AgGrid.Expression` module.

## [10.0.0]

- Added `contextMenu` to `GridConfig`
- Added `AgGrid.ContextMenu` module with predefined context menu actions from `AgGrid`
- Added `AgGrid.Expression` module to evaluate javascript expressions in a safer way.

## [9.1.1]

- Added `ColumnVisible` event type for GridState changes

## [9.1.0]

- Exposing the `ColumnSettings` type alias.

## [9.0.0]

- Added `rowId` to `GridConfig` allowing to configure a custom rowId depending on a data attribute

## [8.0.0]

- Added `suppressRowDeselection` and `rowMultiSelectWithClick` attributes to the `GridConfig`
- Added `selectedIds` to the `GridConfig` allowing to preset a item selection
- Added `onSelectionChange` event to read the current selection whenever the selection changes

## [7.0.1]

- Fix format of zero values when using Currency/Decimal/Percentage formatter.

## [7.0.0]

We added some more properties to the `GridConfig` and the `ColumnSettings` to control the row selection in the table. Since this changes the two types this is a major update. But if you have been using the `defaultSettings` and `defaultGridConfig` then there is no change needed to the configurations.

- Added `checkboxSelection`, `headerCheckboxSelection`, `lockPosition`, and `showDisabledCheckboxes` properties to the `ColumnSettings`
- Added `groupSelectsChildren`, `isRowSelectable`, `rowSelection`, and `suppressRowClickSelection` properties to the `GridConfig`
- Added the `CustomAggregation` variant to the `Aggregation` type in order to use custom aggregations

**Requires at least version 3.0.0 of the `elm-ag-grid` [NPM package](https://www.npmjs.com/package/@mercurymedia/elm-ag-grid/v/3.0.0).**

## [6.0.0]

- Removed the `allowColResize` property on the `GridConfig`. This is now configured per column individually by setting `resizable` on the `ColumnSettings`.
- Added `filterParams` and `rowGroup` to the `ColumnSettings`
- Added `groupDefaultExpanded` to the `GridConfig` to control how many levels of groups are expanded by default
- Added `autoGroupColumnDef` to the `GridConfig` to customize the group-column appearance
- Added `rowGroupPanelShow` to the `GridConfig` to enable the RowGroupPanel

## [5.0.1]

- Bugfix `DecimalRenderer` and `PercentRenderer` aggregation by casting the cell values as numbers.

## [5.0.0]

- Changed the `Renderer` type by adding a new `CurrencyRenderer`, `DecimalRenderer`, and `PercentRenderer` to format cell values into localized strings
- Changed the `sidebar` attribute on the `GridConfig` to a record. The sidebar type has moved into the record on the `panels` attribute - which is now a listing of all enabled toolbar panels. The equivalent values are:
  - `AgGrid.ColumnSidebar` is now `{ defaultSidebar | panels = [AgGrid.ColumnSidebar] }`
  - `AgGrid.FilterSidebar` is now `{ defaultSidebar | panels = [AgGrid.FilterSidebar] }`
  - `AgGrid.BothSidebars` is now `{ defaultSidebar | panels = [AgGrid.ColumnSidebar, AgGrid.FilterSidebar] }`
  - `AgGrid.NoSidebar` is now `{ defaultSidebar | panels = [] }` - which is already the default and therefore doesn't need to be set explicitly
  - The default sidebar behaves exactly like the default sidebar setting before
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
