# elm-ag-grid

Elm integration for the Ag Grid data grid library.

For available configurations of the grid, the columns, and the usage of the grid reference to the documentation of `GridConfig`, `ColumnSettings`, and `grid` in the `AgGrid` module.

An example can be found in the [`examples/`](https://github.com/mercurymedia/elm-ag-grid/tree/master/examples) folder.

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
