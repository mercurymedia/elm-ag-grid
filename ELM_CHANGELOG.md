# Elm Changelog

## [31.0.0]

- Add `Aggregation` Panel to `statusBarPanels` options.

## [30.0.0]

- Add `statusBarPanels` to `GridConfig`

## [29.1.0]

- Add event `visibleRowIdsUpdated` on each model update, containing the currently visible Row Ids

## [29.0.1]

- Change type of `filter` of `NumberFilterAttrs` from `Int` to `Float` to prevent losing decimal values after reloading.

## [29.0.0]

- Add `LargeTextEditor` to enable more options for predefined editors like `agLargeTextCellEditor`
- Moved `SelectionEdtior` to the `CellEditor` type.

## [28.0.1]

- Fix: Update table with empty row data

## [28.0.0]

- Add `Column` custom type to differentiate between columns and column groups
- Add `ColumnGroups`

**Note**: Now the column needs to be wrapped into an `AgGrid.Column` constructor.

## [27.0.2]

- Use AgGrid default bool renderer

## [27.0.1]

- Listening for `editRequest` to handle cell changes

## [27.0.0]

- Add `lockPinned` to `ColumnSettings`

## [26.0.0]

- Add `columnHoverHighlight` and `rowHoverHighlight` to `GridConfig`
- Add `suppressAggFuncInHeader` to `GridConfig`
- Add `pinned` to `GridConfig.autoGroupColumnDef`

## [25.0.0]

- Add `autoHeight` and `wrapText` to `ColumnSettings`

## [24.0.0]

- Added `rowClassRules` to `GridConfig`

## [23.1.0]

- Added `onCellClick` event listener for single cell clicks.

## [23.0.0]

- Changed the `cssClasses` attribute on the custom context menu actions from `List String` to `List (List String, Eval Bool)` to apply certain CSS styles conditionally. This behaviour is similar to the `classList` of the elm/html package.

## [22.0.0]

- Added `cssClasses` attribute to context menu action
- Added `floatingFilter` attribute to ColumnDefs

## [21.0.0]

- ColumnDefs now support a FilterType `DateFilter`, which makes AGGrid intrepret the column as having dates and offering date type specific filtering with date pickers etc.
- Fix: FilterStates as emitted by the `onFilterChanged` event are now encoded to handle all known cases from the AGGrid docs.


## [20.0.0]

- Convert width from an `Int` to a `Float` type on the `ColumnSettings` and `ColumnState`. This fixes an issue where a column with a float width would fail the ColumnState decoder.

## [19.0.0]

- Added `flex`, `pivot`, `pivotIndex`, `rowGroupIndex`, `sort`, and `sortIndex` to `ColumnSettings`
- Using `ColumnState` passed to `GridConfig` to override the `ColumnDefs` passed to the grid view. This allows the `ColumnDefs` to be updated after the component is rendered without overwriting the column states. This resolves a column state caching issue.
- Added `ResetColumns` as column state event

## [18.0.0]

- Add `maintainColumnOrder` to `GridConfig`

## [17.0.0]

- BREAKING_CHANGE: Submenu actions of a custom ContextAction no longer need to be wrapped with `ChildContextAction`
- Percentage formatting now reflects the defined decimal value correctly - e.g. the float `15.5678` with given `decimalPlaces = 2` will be `15.57`

## [16.0.0]

- BREAKING CHANGE: Removed `percentFilterValueGetter`
- BREAKING CHANGE: `PercentRenderer` now requires the value to be the percentage (e.g. `"15" == 15%`, before this was given as decimal `0.15`). The value in the editor will also be the percentage (`15`).

## [15.1.0]

- Exposing `AgGrid.ValueFormat` module

## [15.0.0]

- Changed default `filter` on `ColumnDef` to the new `DefaultFilter` variant (was `SetFilter`). The `DefaultFilter` will determine a default filter and filterValueFormatter by the column renderer. The default values can be overriden by explicitely setting a different `filter` or `filterValueGetter`.

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
