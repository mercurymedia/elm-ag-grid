# elm-ag-grid

Elm integration for the Ag Grid data grid library.

For available configurations of the grid, the columns, and the usage of the grid reference to the documentation of `GridConfig`, `ColumnSettings`, and `grid` in the `AgGrid` module.

An example can be found in the [`examples/`](https://github.com/mercurymedia/elm-ag-grid/tree/master/examples) folder.

## Install

Elm component: `elm install mercurymedia/elm-ag-grid`

It's also required to make the webcomponent from the package available to your project. For example, this can be done by downloading the package from GitHub with `npm` and importing it into the Javascript pipeline.

```json
  "devDependencies": {
    "ag-grid-webcomponent": "git@github.com:mercurymedia/elm-ag-grid.git",
    ...
  }
```

```js
import from "ag-grid-webcomponent";
import { Elm } from "./src/Main.elm";

Elm.Main.init({ node: document.getElementById('app') });
```

## Ag Grid Enterprise

The LicenseManager for Ag Grid Enterprise is exported and can be called to set the license key to enable the enterprise version.

```js
import * as AgGridElm from "ag-grid-webcomponent";

AgGridElm.licenseManager.setLicenseKey("YOUR-LICENSE-KEY");
```

## Themes

To use a theme, add the theme class name to the `config` argument for your grid. For example when using the

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
import "ag-grid-webcomponent";
```
