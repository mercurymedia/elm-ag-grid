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
import from "@mercurymedia/elm-ag-grid";
import { Elm } from "./src/Main.elm";

Elm.Main.init({ node: document.getElementById('app') });
```

**Note:** The package requires at least `ag-grid-community` to be available in the project.

## Package version requirements

The latest [Elm package version](https://package.elm-lang.org/packages/mercurymedia/elm-ag-grid/latest) always works well with the latest [NPM package version](https://www.npmjs.com/package/@mercurymedia/elm-ag-grid/v/latest). Otherwise, please keep the NPM version in the accepted range for the used version of the Elm package to reduce the possibility of errors.

| Elm Version |    Npm Version     |
| :---------: | :----------------: |
|    1.0.0    | 1.0.0 <= v < 1.1.0 |
| 2.0.0 - \*  |     1.1.0 <= v     |

## Ag Grid Enterprise

The `elm-ag-grid` package uses Ag Grid Enterprise features. To enable them install the `ag-grid-enterprise` package and activate it by setting the license key. See the [official Ag Grid documentation](http://54.222.217.254/javascript-grid-set-license/) for further details.

```js
import * as AgGridEnterprise from "ag-grid-enterprise";

AgGridEnterprise.LicenseManager.setLicenseKey("YOUR-LICENSE-KEY");
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
import "ag-grid-community/dist/styles/ag-theme-balham.css";
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

To reference the component application and use it for the table, you must register the component in the `window.ElmAgGridComponentRegistry` object. The key is the name used in your main application to refer to the component and the value is the object containing the `init` function to initialize the Elm application.

You can either just use the usual Elm object for this:

```javascript
import { Elm } from "./src/Components/Link.elm";

window.ElmAgGridComponentRegistry = {
  linkRenderer: Elm.Components.Link,
};
```

Or define your own object with an `init` function if you want to use ports for communication between the applications.

**Note:** In this case, make sure to return the initialized application to be able to access the ports from the cellRenderer.

```javascript
import { Elm } from "./src/Components/Button.elm";

window.ElmAgGridComponentRegistry = {
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
};
```

**The function is called with an object containing the keys `node` and `flags`. The flags are containing the usual [AgGrid cellRendererParams](https://www.ag-grid.com/javascript-data-grid/component-cell-renderer/#reference-ICellRendererParams) and the defined `componentParams` from your `AppRenderer` definition.**

### Utilizing a component in Elm

To use a component for cell rendering, you can use the `AppRenderer { componentName : String, componentParams : Maybe Json.Encode.Value } (dataType -> String)` renderer in your column definition.

```elm
    { field = "details"
    , renderer = AppRenderer { componentName = "linkRenderer", componentParams = Nothing } .url
    , headerName = "Details"
    , settings = { defaultSettings | editable = False }
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
