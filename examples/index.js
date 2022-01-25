import "@webcomponents/custom-elements";
import * as AgGridElm from "ag-grid-webcomponent";
import { Elm } from "./src/Main.elm";

import "ag-grid-community/dist/styles/ag-grid.css";
import "ag-grid-community/dist/styles/ag-theme-balham.css";
import "/styles/ag_grid_custom.css";

// For AG Grid Enterprise you can set license key by calling:
// AgGridElm.licenseManager.setLicenseKey("YOUR-LICENSE-KEY");

window.AgGrid = {
  init: function ({ node }) {
    Elm.Main.init({ node: node });
  },
};
