import "@webcomponents/custom-elements";

// This would usually be the package import
// import ElmAgGrid from "@mercurymedia/elm-ag-grid";
import ElmAgGrid from "../ag-grid-webcomponent";
import { Elm } from "./src/Main.elm";

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

// For AG Grid Enterprise features set your license key here:
// LicenseManager.setLicenseKey("YOUR LICENSE KEY");

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

import "@ag-grid-community/styles/ag-grid.css";
import "@ag-grid-community/styles/ag-theme-balham.css";
import "./styles/ag_grid_custom.css";

// Component import
import ButtonRenderer from "./src/Components/Button.elm";
import LinkRenderer from "./src/Components/Link.elm";
import Editor from "./src/Components/Editor.elm";

let app;

window.AgGrid = {
  init: function ({ node }) {
    app = Elm.Main.init({ node: node });

    new ElmAgGrid({
      app: app,
      apps: {
        // You can simply provide the usual Elm object to register your component.
        // Or, to use ports for communication between your component and main application
        // you can specify an object with a `init` function yourself that accepts a `node`
        // and `flags`.
        // Note: The component application needs to be returned in order to access the ports
        // in the cellRenderer.
        editor: Editor.Elm.Components.Editor,
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
      },

      aggregations: {
        // Custom aggregation functions
        "Min&Max": function (params) {
          const result = {
            min: null,
            max: null,
            toString: function () {
              return this.min + " .. " + this.max;
            },
          };

          params.values.forEach((value) => {
            const groupNode = value && typeof value === "object";

            const minValue = groupNode ? value.min : value;
            const maxValue = groupNode ? value.max : value;

            result.min = Math.min(minValue, result.min);
            result.max = Math.max(maxValue, result.max);
          });

          return result;
        },
      },
    });

    app.ports.setItem.subscribe(function (args) {
      localStorage.setItem(args[0], JSON.stringify(args[1]));
    });

    app.ports.requestItem.subscribe(function (key) {
      requestAnimationFrame(function () {
        app.ports.receivedItem.send([
          key,
          JSON.parse(localStorage.getItem(key)),
        ]);
      });
    });

    app.ports.setFilterState.subscribe(function (state) {
      localStorage.setItem("filter-state", JSON.stringify(state));
    });

    app.ports.requestFilterState.subscribe(function () {
      requestAnimationFrame(function () {
        app.ports.receivedFilterState.send(JSON.parse(localStorage.getItem("filter-state")))
      });
    });
  },
};
