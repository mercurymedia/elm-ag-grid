# NPM Changelog

## [5.0.0]

- Updates AG Grid to 33.3.0
- Dependencies are now added as their whole module, but you can import only the ones you need (as explained [here](https://www.ag-grid.com/javascript-data-grid/upgrading-to-ag-grid-33/#migrating-from-modules)):
  ```json
    "ag-grid-community": "^33.3.0",
    "ag-grid-enterprise": "^33.3.0",
    ```
  - Example of importing only the required modules:
    ```js
    import { ModuleRegistry, ClientSideRowModelModule } from '@ag-grid-community'
    import { LicenseManager, ColumnsToolPanelModule, FiltersToolPanelModule, MenuModule, RangeSelectionModule, RichSelectModule, RowGroupingModule, SideBarModule } from '@ag-grid-enterprise'

    ModuleRegistry.registerModules([
      ClientSideRowModelModule,
      ColumnsToolPanelModule,
      FiltersToolPanelModule,
      MenuModule,
      RangeSelectionModule,
      RichSelectModule,
      RowGroupingModule,
      SideBarModule
    ]);
    ```
  ```

## [4.2.1]

- Removed the unsupported `getLocaleTextFunc()` from the `Reset Columns` custom action

## [4.2.0]

- Add `onModelDataUpdated` event, which fires the `visibleRowIdsUpdated` event, containing the currently visible row ids.

## [4.1.1]

- Add the following properties to the `editRequest` event:
  - `field` the name of the actual changed field
  - `newValue` the new value of the field
  - `oldValue` the old value of the field

## [4.1.0]

- Add support for column groups

## [4.0.2]

- Use AgGrid default bool renderer

## [4.0.1]

- AgGrid API now exposed again as `<custom-element>.api` as it was before 4.0.0

## [4.0.0]

- Enabled `readOnlyEdit` in AgGrid and sending `editRequest` events to notify about changes
- Updates AG Grid to 31.1.x
- AG Grid dependencies now via modules (https://www.ag-grid.com/javascript-data-grid/modules/). If you are upgrading from an older version, you need to change your NPM dependencies to use the module-based imports. Also check your Browser console for warnings from AG Grid.

   - Replace ag-grid-community dependency with @ag-grid-community/core
   - Replace ag-grid-enterprise dependency with @ag-grid-enterprise/core
   - Add module-based dependencies as needed:
     ```json
       "@ag-grid-community/styles": "^31.1.0",
       "@ag-grid-community/client-side-row-model": "^31.1.0",
       "@ag-grid-enterprise/column-tool-panel": "^31.1.0",
       "@ag-grid-enterprise/filter-tool-panel": "^31.1.0",
       "@ag-grid-enterprise/menu": "^31.1.0",
       "@ag-grid-enterprise/range-selection": "^31.1.0",
       "@ag-grid-enterprise/rich-select": "^31.1.0",
       "@ag-grid-enterprise/row-grouping": "^31.1.0",
       "@ag-grid-enterprise/side-bar": "^31.1.0",
     ```
   - Register AgGrid components as necessary:
     ```js
       import { ModuleRegistry } from '@ag-grid-community/core'
       import { ClientSideRowModelModule } from '@ag-grid-community/client-side-row-model'
       import { LicenseManager } from '@ag-grid-enterprise/core'
       import { ColumnsToolPanelModule } from '@ag-grid-enterprise/column-tool-panel'
       import { FiltersToolPanelModule } from '@ag-grid-enterprise/filter-tool-panel'
       import { MenuModule } from '@ag-grid-enterprise/menu'
       import { RangeSelectionModule } from '@ag-grid-enterprise/range-selection'
       import { RichSelectModule } from '@ag-grid-enterprise/rich-select'
       import { RowGroupingModule } from '@ag-grid-enterprise/row-grouping'
       import { SideBarModule } from '@ag-grid-enterprise/side-bar'

       ModuleRegistry.registerModules([
         ClientSideRowModelModule,
         ColumnsToolPanelModule,
         FiltersToolPanelModule,
         MenuModule,
         RangeSelectionModule,
         RichSelectModule,
         RowGroupingModule,
         SideBarModule
       ]);
     ```

## [3.7.1]

- Explicitly check in column events for `finished === false`

## [3.7.0]

- Handling `rowClassRules` as expressions
- Dispatch column events when `finished` is set

## [3.6.0]

- Added support for conditional `cssClasses` in context menu items

## [3.5.0]

- Menu items on column headers have been updated slightly to customize the default action "resetColumns". It now triggers a column state change event, besides the usual action.

## [3.4.2]

- Set initial cell editor value

## [3.4.1]

- Remove unintended space for expression operator OR

## [3.4.0]

- Added an `app_editor` cellEditor component to use Elm apps for editing cell values.

## [3.3.4]

- Fixed change detection for case-sensitive attributes (i.e. `quickFilterText`)

## [3.3.3]

- Fix: Ignore rows without data (i.e. footer) when evaluating expressions

## [3.3.2]

- Changed the AgGrid expression string for `cellClassRules` to our own `Expression` object for consistency.

## [3.3.1]

- Applying `editable` callbacks on ColumnDefs

## [3.3.0]

- Added `expression.js` to evaluate serialized expressions for the context menu actions

## [3.2.2]

- Add setter for `columnDefs` to make use of the gridApi

## [3.2.1]

- Listening for `onColumnVisible` event for column state changes

## [3.2.0]

- Added callback value to customize the row ID

## [3.1.1]

- Using null-safe access operator for `getRowId`

## [3.1.0]

- Added customized `onSelectionChange` event listener that returns now the current selection
- Added `selectedIds` setter to handle custom selections
- Fixed a bug that no leading minus could be entered without any number in the input field
- Fixed a bug that no CTRL actions (cut, copy, paste, ...) where usable in the decimal input field

## [3.0.0]

- Added `isRowSelectable` callback to the GridOptions
- Changed: Updated `ag-grid-community` and `ag-grid-enterprise` peer-dependency to 29.1.0
- The ElmAgGrid class now needs to be instantiated manually in order to register the webcomponents. The shortest form would just be `new ElmAgGrid()`
- Additionally, the custom CellRenderer components defined via `window.ElmAgGridComponentRegistry` are now to be passed as an argument to the ElmAgGrid class

```js
new ElmAgGrid({ apps: { customRenderer: Elm.Components.Custom } });
```

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
