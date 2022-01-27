import "@webcomponents/custom-elements";
// import * as AgGridEnterprise from "ag-grid-enterprise";

import "elm-ag-grid";
import { Elm } from "./src/Main.elm";

import "ag-grid-community/dist/styles/ag-grid.css";
import "ag-grid-community/dist/styles/ag-theme-balham.css";
import "/styles/ag_grid_custom.css";

// For AG Grid Enterprise you can set license key by calling:
// AgGridEnterprise.LicenseManager.setLicenseKey("YOUR-LICENSE-KEY");

window.AgGrid = {
  init: function ({ node }) {
    Elm.Main.init({ node: node });
  },
};
