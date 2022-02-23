import "@webcomponents/custom-elements";
// import * as AgGridEnterprise from "ag-grid-enterprise";

// This would usually be the pacakge import
// import "@mercurymedia/elm-ag-grid";
import "../ag-grid-webcomponent";
import { Elm } from "./src/Main.elm";

import "ag-grid-community/dist/styles/ag-grid.css";
import "ag-grid-community/dist/styles/ag-theme-balham.css";
import "./styles/ag_grid_custom.css";

// For AG Grid Enterprise you can set license key by calling:
// AgGridEnterprise.LicenseManager.setLicenseKey("YOUR-LICENSE-KEY");

// Component import
import ButtonRenderer from "./src/Components/Button.elm";
import LinkRenderer from "./src/Components/Link.elm";

let app;

// You can simply provide the usual Elm object to register your component.
// Or, to use ports for communication between your component and main application
// you can specify an object with a `init` function yourself that accepts a `node`
// and `flags`.
// Note: The component application needs to be returned in order to access the ports
// in the cellRenderer.
window.ElmAgGridComponentRegistry = {
  linkRenderer: LinkRenderer.Elm.Components.Link,
  buttonRenderer: {
    init: function ({ node, flags }) {
      let component = ButtonRenderer.Elm.Components.Button.init({
        node: node,
        flags: flags,
      });

      component.ports.onButtonClick.subscribe(function (id) {
        if (app) app.ports.buttonClicked.send(id);
      });

      return component;
    },
  },
};

window.AgGrid = {
  init: function ({ node }) {
    app = Elm.Main.init({ node: node });
  },
};
