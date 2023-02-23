import * as agGrid from "ag-grid-community";

import cellRenderer from "./cell_renderer";
import cellEditor from "./cell_editor";
import appRenderer from "./app_renderer";

let CUSTOM_AGGREGATIONS = {};

class AgGrid extends HTMLElement {
  constructor() {
    super();
    this._preInitAgGridAttributes = {};
    this._preInitCustomAttributes = {};
    this._propertyMap = this._createPropertyMap();
    this._events = {};
  }

  _createPropertyMap() {
    return agGrid.ComponentUtil.ALL_PROPERTIES.concat(setterProperties).reduce(
      (map, property) => {
        map[property.toLowerCase()] = property;
        return map;
      },
      {}
    );
  }

  _definesSetter(attribute) {
    const descriptor = Object.getOwnPropertyDescriptor(
      AgGrid.prototype,
      attribute
    );
    return descriptor && typeof descriptor.set === "function";
  }

  loadAttribute(attr) {
    let gridElement = this.getAttribute(attr);
    return gridElement ? JSON.parse(gridElement) : undefined;
  }

  set gridOptions(options) {
    let globalEventListener = this.globalEventListener.bind(this);

    this._gridOptions = agGrid.ComponentUtil.copyAttributesToGridOptions(
      options,
      this._preInitAgGridAttributes
    );

    // Can only be instantiated once
    if (!this._initialised) {
      // prevent instantiating multiple grids
      let gridParams = { globalEventListener };
      this._agGrid = new agGrid.Grid(this, this._gridOptions, gridParams);

      this.api = options.api;
      this.columnApi = options.columnApi;
      this._initialised = true;

      Object.entries(this._preInitCustomAttributes).map(
        // Call setter for the custom attributes
        ([key, value]) => (this[key] = value)
      );
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
    return agGrid.ComponentUtil.ALL_PROPERTIES.concat(setterProperties).map(
      (property) => property.toLowerCase()
    );
  }

  set columnState(state) {
    this.columnApi.applyColumnState({ state: state, applyOrder: true });
  }

  set disableResizeOnScroll(disabled) {
    this._addEventHandler(
      "onBodyScroll",
      "disableResizeOnScroll",
      function (params) {
        if (!disabled) params.api.sizeColumnsToFit();
      }
    );
  }

  set filterState(state) {
    this.api.setFilterModel(state);
  }

  set sizeToFitAfterFirstDataRendered(sizeToFit) {
    this._addEventHandler(
      "onFirstDataRendered",
      "sizeToFitAfterFirstDataRendered",
      function (params) {
        if (sizeToFit) params.api.sizeColumnsToFit();
      }
    );
  }

  set rowData(data) {
    this._applyChange("rowData", data);

    if (this._agGrid.gridOptions.rowData === null) {
      this.api.showNoRowsOverlay();
    }
  }

  _applyChange(propertyName, newValue) {
    let changeObject = {};
    changeObject[propertyName] = { currentValue: newValue };

    agGrid.ComponentUtil.processOnChange(changeObject, this.api);
  }

  _addEventHandler(eventName, type, callback) {
    let collection = this._events[eventName] || {};
    collection[type] = callback;

    this._events = collection;

    this._gridOptions[eventName] = function (args) {
      Object.values(collection).map((event) => event(args));
    };
  }

  attributeChangedCallback(name, oldValue, newValue) {
    // Re-Process GridConfig when an "Elm" property changed.
    let gridPropertyName = this._propertyMap[name];
    let parsedNewValue = newValue ? JSON.parse(newValue) : newValue;

    if (this._definesSetter(gridPropertyName)) {
      if (this._initialised) {
        // for subsequent (post gridOptions) changes
        this[gridPropertyName] = parsedNewValue;
      } else {
        // for properties set before gridOptions is called
        this._preInitCustomAttributes[gridPropertyName] = parsedNewValue;
      }
    } else {
      if (this._initialised) {
        // for subsequent (post gridOptions) changes
        this._applyChange(name, parsedNewValue);
      } else {
        // for properties set before gridOptions is called
        this._preInitAgGridAttributes[gridPropertyName] = parsedNewValue;
      }
    }
  }

  connectedCallback() {
    this._initializeGrid();

    this._broadcastColumnState();
    this._broadcastFilterState();
  }

  _initializeGrid() {
    this.gridOptions = {
      components: {
        ...cellRenderer,
        ...cellEditor,
        appRenderer,
      },
      aggFuncs: CUSTOM_AGGREGATIONS,

      isRowSelectable: (params) => {
        return !!params.data && params.data.rowCallbackValues.isRowSelectable;
      },
    };

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

  _broadcastColumnState() {
    const columnEvents = [
      "onSortChanged",
      "onColumnMoved",
      "onGridColumnsChanged",
      "onColumnResized",
    ];
    const _this = this;

    columnEvents.map((event) =>
      this._addEventHandler(event, "columnEvents", function (params) {
        const stateChangeEvent = new CustomEvent("columnStateChanged", {
          detail: {
            event: params,
            columnState: params.columnApi.getColumnState(),
          },
        });
        _this.dispatchEvent(stateChangeEvent);
      })
    );
  }

  _broadcastFilterState() {
    const filterEvents = ["onFilterChanged"];
    const _this = this;

    filterEvents.map((event) =>
      this._addEventHandler(event, "filterEvents", function (params) {
        const stateChangeEvent = new CustomEvent("filterStateChanged", {
          detail: {
            event: params,
            filterState: params.api.getFilterModel(),
          },
        });
        _this.dispatchEvent(stateChangeEvent);
      })
    );
  }
}

const setterProperties = Object.entries(
  Object.getOwnPropertyDescriptors(AgGrid.prototype)
)
  .filter(([_key, descriptor]) => typeof descriptor.set === "function")
  .map(([key]) => key);

export default class ElmAgGrid {
  constructor({ apps = {}, aggregations = {} } = {}) {
    window.ElmAgGridComponentRegistry = apps;
    CUSTOM_AGGREGATIONS = aggregations;

    customElements.define("ag-grid", AgGrid);
  }
}
