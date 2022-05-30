import * as agGrid from "ag-grid-community";

import cellRenderer from "./cell_renderer";
import cellEditor from "./cell_editor";
import appRenderer from "./app_renderer";

const elmProperties = [
  "disableResizeOnScroll",
  "sizeToFitAfterFirstDataRendered",
];

const agGridProperties = agGrid.ComponentUtil.ALL_PROPERTIES.filter(
  (property) => property !== "gridOptions"
);

const observedProperties = agGridProperties.concat(elmProperties);

class AgGrid extends HTMLElement {
  constructor() {
    super();
    this._attributes = {};
    this._propertyMap = this._createPropertyMap();
  }

  _createPropertyMap() {
    return observedProperties.reduce((map, property) => {
      map[property.toLowerCase()] = property;
      return map;
    }, {});
  }

  loadAttribute(attr) {
    let gridElement = this.getAttribute(attr);
    return gridElement ? JSON.parse(gridElement) : undefined;
  }

  set gridOptions(options) {
    let globalEventListener = this.globalEventListener.bind(this);

    this._gridOptions = agGrid.ComponentUtil.copyAttributesToGridOptions(
      options,
      this._attributes
    );

    // prevent instantiating multiple grids
    if (!this._initialised) {
      let gridParams = { globalEventListener };
      this._agGrid = new agGrid.Grid(this, this._gridOptions, gridParams);

      this.api = options.api;
      this.columnApi = options.columnApi;
      this._initialised = true;
    }
  }

  setAttribute() {
    // Problem: The integrated customElement-package does not trigger the attributeChangedCallback
    // because it distinguishes between uppercase and lowercase. However, the native CustomElement
    // function doesn't, which is why this workaround is theoretically not necessary there.
    // For browsers that use the package, the argument must be edited beforehand.
    //
    // There is already a PR in the package project for solving the problem. Should this PR be
    // merged one day, this workaround can probably be removed.
    //
    // Outstanding PR: (https://github.com/webcomponents/custom-elements/pull/168)
    arguments[0] = arguments[0].toLowerCase();
    HTMLElement.prototype.setAttribute.apply(this, arguments);
  }

  static get observedAttributes() {
    return observedProperties.map((property) => property.toLowerCase());
  }

  _isElmProperty(name) {
    elmProperties.some((property) => property === name);
  }

  attributeChangedCallback(name, oldValue, newValue) {
    // Re-Process GridConfig when an "Elm" property changed.
    if (this._isElmProperty(name)) return this._process_grid_config();

    let gridPropertyName = this._propertyMap[name];
    let parsedNewValue = newValue ? JSON.parse(newValue) : newValue;

    // for properties set before gridOptions is called
    this._attributes[gridPropertyName] = parsedNewValue;

    if (this._initialised) {
      // for subsequent (post gridOptions) changes
      let changeObject = {};
      changeObject[gridPropertyName] = {
        currentValue: parsedNewValue,
      };

      agGrid.ComponentUtil.processOnChange(
        changeObject,
        this._gridOptions,
        this.api,
        this.columnApi
      );
    }
  }

  connectedCallback() {
    this._process_grid_config();
  }

  _process_grid_config() {
    const agGrid = this;
    const gridOptions = {
      components: {
        ...cellRenderer,
        ...cellEditor,
        appRenderer,
      },

      onFirstDataRendered: function () {
        if (!!agGrid.loadAttribute("sizeToFitAfterFirstDataRendered"))
          gridOptions.api.sizeColumnsToFit();
      },

      onBodyScroll: function () {
        // Triggers the resize for the last space-filling column.
        // onColumnResized didn't worked here unfortunately, since it kept firing events..
        // Probably the called resize does re-trigger this ...
        if (!agGrid.loadAttribute("disableresizeonscroll"))
          gridOptions.api.sizeColumnsToFit();
      },
    };

    this.gridOptions = gridOptions;

    if (gridOptions.rowData === null) {
      this.api.showNoRowsOverlay();
    }

    // Use autoHeight if no height was specified on the DOM element otherwise.
    if (!this.style.height) this.api.setDomLayout("autoHeight");
  }

  globalEventListener(eventType, event) {
    let eventLowerCase = eventType.toLowerCase();
    let browserEvent = new Event(eventLowerCase);

    let browserEventNoType = browserEvent;
    browserEventNoType.agGridDetails = event;

    // for when defining events via agGrid.addEventListener('columnresized', function (event) {...
    this.dispatchEvent(browserEvent);

    // for when defining events via agGrid.oncolumnresized = function (event) {....
    let callbackMethod = "on" + eventLowerCase;
    if (typeof this[callbackMethod] === "function") {
      this[callbackMethod](browserEvent);
    }
  }
}

customElements.define("ag-grid", AgGrid);
