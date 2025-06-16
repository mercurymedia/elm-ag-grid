# elm-ag-grid

Elm integration for the Ag Grid data grid library.

For available configurations of the grid, the columns, and the usage of the grid reference to the documentation of `GridConfig`, `ColumnSettings`, and `grid` in the `AgGrid` module.

An example can be found in the [`examples/`](https://github.com/mercurymedia/elm-ag-grid/tree/main/examples) folder.

## Install

**Elm component:** `elm install mercurymedia/elm-ag-grid`

It's also required to make the webcomponent from the package available to your project. This can be done by installing the package from NPM.

```sh
  npm i @mercurymedia/elm-ag-grid
```

And then importing it into the Javascript pipeline.

```js
import ElmAgGrid from "@mercurymedia/elm-ag-grid";
import { Elm } from "./src/Main.elm";

new ElmAgGrid();

Elm.Main.init({ node: document.getElementById("app") });
```

For most features of AG Grid it is necessary to install modules and register them:

```js
import { ModuleRegistry, ClientSideRowModelModule } from 'ag-grid-community'

ModuleRegistry.registerModules([
  ClientSideRowModelModule
]);
```

AG Grid will print warnings into the browser console if modules are missing. For a full list of modules, see https://www.ag-grid.com/javascript-data-grid/modules/.

## Package version requirements

The latest [Elm package version](https://package.elm-lang.org/packages/mercurymedia/elm-ag-grid/latest) always works well with the latest [NPM package version](https://www.npmjs.com/package/@mercurymedia/elm-ag-grid/v/latest). Otherwise, please keep the NPM version in the accepted range for the used version of the Elm package to reduce the possibility of errors.

|   Elm Version   |    Npm Version     |
| :-------------: | :----------------: |
|      1.0.0      | 1.0.0 <= v < 1.1.0 |
|  2.0.0 - 3.0.0  | 1.1.0 <= v < 1.3.0 |
|  3.1.0 - 4.0.0  |       1.3.0        |
|  5.0.0 - 6.0.0  |       2.1.0        |
|  7.0.0 - 7.0.1  |       3.0.0        |
|  8.0.0 - 9.1.1  |       3.1.0        |
| 10.0.0 - 11.0.0 |       3.3.0        |
|     12.0.0      |       3.3.1        |
|     13.0.0      |       3.3.2        |
| 14.0.0 - 18.0.0 |   3.4.0 - 3.4.2    |
| 19.0.0 - 22.0.0 |       3.5.0        |
| 23.0.0 - 23.1.0 |       3.6.0        |
| 24.0.0 - 27.0.2 |   3.7.0 - 4.0.2    |
| 28.0.0 - 29.0.0 |   3.7.0 - 4.1.1    |
| 29.1.0 - 31.0.0 |       4.2.0        |
|     32.0.0      |       4.2.1        |
|     33.0.0      |       5.0.0        |


## Ag Grid Enterprise

The `elm-ag-grid` package uses Ag Grid Enterprise features. To enable them install the `@ag-grid-enterprise/core` package and activate it by setting the license key. See the [official Ag Grid documentation](http://54.222.217.254/javascript-grid-set-license/) for further details.

```js
import { LicenseManager } from '@ag-grid-enterprise/core'

LicenseManager.setLicenseKey("YOUR LICENSE KEY");
```

## Themes

To use a theme, add the theme class name to the `config` argument for your grid. For example when using the "balham" theme:

```elm
viewGrid : Model -> Html Msg
viewGrid model =
    let
        gridConfig =
            AgGrid.defaultGridConfig
                |> (\config ->  { config | themeClasses = Just "ag-theme-balham ag-basic" })
    in
    AgGrid.grid gridConfig [] [] []
```

You just need to make sure that the classes are available to you. For example, you can import pre-built bundles from the `ag-grid-community` package.

```js
import "ag-grid-community/styles/ag-theme-balham.css";
```

## Polyfill

To support browsers that don't have built-in support for the Web Components API, you can install a Web Component Polyfill (for example: [@webcomponents/custom-elements](https://github.com/webcomponents/polyfills/tree/master/packages/custom-elements)) to simulate the missing browser capabilities. This just needs to be loaded before the Ag-Grid-Webcomponent.

```js
import "@webcomponents/custom-elements";
import "@mercurymedia/elm-ag-grid";
```

## Custom views for cells

A custom view for the cell (such as a button or link) can be defined with a separate Elm application which gets rendered into the cell. The application must therefore be defined as `Browser.element`.

FYI, there are two components in the [example application](https://github.com/mercurymedia/elm-ag-grid/tree/main/examples) used that you might find very useful.

### Register Component

To reference the component application and use it for the table, you must register the component to the package. This can be done by configuring the ElmAgGrid class when instantiating and providing an object with your components via the `apps` config. The key is the name used in your main application to refer to the component and the value is the object containing the `init` function to initialize the Elm application.

You can either just use the usual Elm object for this:

```javascript
import { Elm } from "./src/Components/Link.elm";

new ElmAgGrid({
  apps: {
    linkRenderer: Elm.Components.Link,
  },
});
```

Or define your own object with an `init` function if you want to use ports for communication between the applications.

**Note:** In this case, make sure to return the initialized application to be able to access the ports from the cellRenderer.

```javascript
import { Elm } from "./src/Components/Button.elm";

new ElmAgGrid({
  apps: {
    buttonRenderer: {
      init: function ({ node, flags }) {
        let component = Elm.Components.Button.init({
          node: node,
          flags: flags,
        });

        component.ports.onButtonClick.subscribe(function (id) {
          // This `app` is the main application
          if (app) app.ports.buttonClicked.send(id);
        });

        return component;
      },
    },
  },
});
```

**The function is called with an object containing the keys `node` and `flags`. The flags are containing the usual [AgGrid cellRendererParams](https://www.ag-grid.com/javascript-data-grid/component-cell-renderer/#reference-ICellRendererParams) and the defined `componentParams` from your `AppRenderer` definition.**

### Utilizing a component in Elm

To use a component for cell rendering, you can use the `AppRenderer { componentName : String, componentParams : Maybe Json.Encode.Value } (dataType -> String)` renderer in your column definition.

```elm
    { field = "details"
    , renderer = AppRenderer { componentName = "linkRenderer", componentParams = Nothing } .url
    , headerName = "Details"
    , settings = { defaultSettings | editable = Expression.Const False }
    }
```

The `componentName` is the reference to the registered component and the `componentParams` can be defined to share information from the main application with the component application. The `componentParams` do not depend on the row data and will always be the same for all rows.

The `(dataType -> String)` part makes it possible to provide a cell value that can be used in your component application if needed.

It's also possible to encode complex data into a string that can then be decoded in the component application, if you want to share more information.

### Component updates while rendered

To respond to component updates while the component is already initialized, you can implement the `componentRefresh` port in your component application, which will get the similar `flags` value as when the application is initialized.

```elm
port componentRefresh : (Flags -> msg) -> Sub msg
```

## Custom CellEditors

While the default editor derives from the defined `renderer`, it can also be overridden. Either by using another existing ag-grid editor (e.g. "agLargeTextCellEditor") or by using another Elm app to render the editor.

In order to use an Elm app, the component must be registered similar to the [custom view renderers](https://github.com/mercurymedia/elm-ag-grid/tree/main/#register-component). After that, the component can be used as a `customCellEditor` in your application.

```elm
    { field = "info"
    , renderer = StringRenderer (.infos >> String.join ", ")
    , headerName = "Info"
    , settings = { defaultSettings | editable = Expression.Const True, customCellEditor = AgGrid.AppEditor { componentName = "editor", componentParams = Nothing } }
    }
```

To notify ag-grid of the changed value for the cell, you need to set up a `currentValue` port in your cell editor component. This needs to be called every time the cell value is changed.

```elm
port currentValue : String -> Cmd msg
```

Normally this can be any type - the renderer just has to be able to interpret it. So it's even possible to work with JSON in the cells as long as the editor understands it and the renderer can interpret it. In combination with a custom cell renderer, this could lead to fancy data representations.

## Saving/Restoring grid columns and filters

The current column state is sent whenever a column changes.

Callbacks listened for column state updates:

- `onSortChanged`
- `onColumnMoved`
- `onGridColumnsChanged`
- `onColumnResized`

The changes can be retrieved and evaluated via the `onColumnStateChanged` event. This returns the event that led to the change and a list of column states.
The column state list can be used to restore the column state in the table (e.g. when loaded from local storage).

```elm
type Msg = ColumnStateChanged { event : { type_ : String }, states : List ColumnState }

AgGrid.grid { gridConfig | columnState = model.columnState } [ onColumnStateChanged ColumnStateChanged ] [] []
```

Similar can be done for the filter state using the `onFilterStateChanged` event.

```elm
type Msg = FilterStateChanged { event : { type_ : String }, states : Dict String FilterState }

AgGrid.grid { gridConfig | filterState = model.filterState } [ onFilterStateChanged FilterStateChanged ] [] []
```

## Value formatting

The package allows defining `valueGetter`, `valueFormatter`, `valueParser`, `valueSetter`, and `filterValueFormatter` as expressions for formatting cell values.
These make it possible to change the type of the cell value the table works with (e.g. strings parsed as numbers to allow aggregations - valueGetter), to format values displayed to the user in the table/filter (e.g. with thousand separators and currency symbol - valueFormatter/filterValueFormatter), and to parse user input before applying the value (e.g. parsing a formatted currency value back into a floating-point number string - valueParser).

**For a detailed explanation of what the expressions can do, refer to the AgGrid documentation.**

The package provides preconfigured value formatting for currencies, decimals, and percentages. Those are available as a `Renderer` type and already configure a certain `valueFormatter`, `valueGetter`, `filterValueFormatter`, and `cellEditor`. If required, the formatting can be overwriten by setting a `valueFormatter`/`filterValueFormatter` yourself on the `ColumnDef`. Also, these predefined expressions can be applied individually to other `Renderer` types if necessary. These are available in the `AgGrid.ValueFormat` module.

- **CurrencyRenderer** to format floating-point strings into localized currency strings (e.g. '1000.15' --> '1.000,15 €')
- **DecimalRenderer** to format floats into localized strings (e.g. 1000.8 --> '1.000,8')
- **PercentRenderer** to format floats into localized percent strings (e.g. 0.22 --> '22%')

## Filtering

By default, each column will use a `filter` and a `filterValueGetter` depending on the renderer. To override it, you can change the `filter` and `filterValueGetter` on the `ColumnSettings`.

## Master-Detail

**Requires AgGrid Enterprise**

Custom Detail views can be defined similar to the [custom cell views](https://github.com/mercurymedia/elm-ag-grid/tree/main/#custom-views-for-cells) by defining the component on the `GridConfig`.

```elm
  { gridConfig | detailRenderer = Just { componentName = "detailRenderer", componentParams = Nothing, rowHeight = Nothing } }
```

As with the custom cell views, the `componentName` refers to the [component](https://github.com/mercurymedia/elm-ag-grid/tree/main/#register-component) and the `componentParams` can be used to pass information from the main application to the detail application (e.g. auth tokens). The AgGrid default detail height can be overridden by specifying a new fixed `rowHeight` value, which applies equally to all detail views.

To see the actual MasterDetail view the `GroupRenderer` can be used on a column to group the row.

```elm
  { renderer = AgGrid.GroupRenderer (.id >> String.fromInt), ... }
```

## Aggregation

**Requires AgGrid Enterprise**

Aggregation for a column can be defined by setting the `aggFunc` setting on the `ColumnSettings`. This may require that the cell's value be specified in the correct data type.
Not all aggregation functions may work with string values. Using a `valueGetter` expression can help with this.

```elm
  { settings = { defaultSettings | aggFunc = AvgAggregation, valueGetter = Just "Number(data.cost)" }}
```

### Customizing Aggregation

Similar to [Register Component](#register-component), custom aggregation functions can be defined by passing the custom configuration during the instantiation to the ElmAgGrid class. The key is the name of the aggregation function and the value is the implementation accepting the ag-grid params and returning the aggregated value.

```js
new ElmAgGrid({
  aggregations: {
    foo: function (params) {
      return "bar";
    },
  },
});
```

This aggregation can be referenced in Elm by using the `CustomAggregation` type when defining a `aggFunc`.

```elm
{ ..., settings = { defaultSettings | aggFunc = CustomAggregation "foo" }}
```

## ContextMenu

**Requires AgGrid Enterprise**

Context menu actions can be defined in Elm in the `gridConfig` by using the `AgGrid.ContextMenu` module. The predefined context menu actions are covered within that module.

```elm
gridConfig =
    { defaultGridConfig
        | contextMenu =
            Just
                [ AgGrid.ContextMenu.autoSizeAllContextAction ]
        }
```

To create a custom context action we make use of events to handle the action in elm.

```elm
gridConfig =
    { defaultGridConfig
        | contextMenu =
            Just
                [ AgGrid.ContextMenu.contextAction
                    { defaultActionAttributes
                        | name = "Increase counter"
                        , actionName = Just "incrementCounter"
                    }
                ]
        }

-- The String contains the clicked action name
type Msg =
  ContextMenuAction (Result DecodeError Data, String)


view =
  AgGrid.grid gridConfig
      [ AgGrid.onContextMenu dataDecoder ContextMenuAction ]
      columns
      data
```

The `disabled` attribute uses the `AgGrid.Expression` module, to serialize expressions in a save way. This makes sure that we prevent XSS atacks.

```elm
import AgGrid.Expression as Expression

...

AgGrid.ContextMenu.contextAction
    { defaultActionAttributes
        | name = "Increase counter"
        , action = Just "incrementCounter"
        , disabled = Expression.Expr (Expression.lte (Expression.value "id") (Expression.int 10))
    }
```

## StatusBar

To add statusBar Panels, add the `StatusBarModule` to the Registry and add the StatusBarPanels you want to the gridConfig. Check [here]https://www.ag-grid.com/javascript-data-grid/status-bar/ for a bunch of options.

```elm
gridConfig =
    { defaultGridConfig
        | statusBarPanels =
            [ { statusPanel = AgGrid.Aggregation [ AgGrid.SumPanelAggregation, AgGrid.AvgPanelAggregation ], align = AgGrid.Left }
            , { statusPanel = AgGrid.TotalRowCount, align = AgGrid.Left }
            ]
        }
```

## Examples

To run the examples in the browser clone the repo and run:

```sh
$ npm start
```

Open you browser at [localhost:1234](http://localhost:1234)
