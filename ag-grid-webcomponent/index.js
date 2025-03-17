import { createGrid, ComponentUtil } from "@ag-grid-community/core";

import cellEditor from "./cell_editor";
import appRenderer from "./app_renderer";
import appEditor from "./app_editor";
import dateRangeFilter from "./date_range_filter";
import expression from "./expression";

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
    return ComponentUtil.ALL_PROPERTIES.concat(setterProperties).reduce(
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

  set rowClassRules(rules) {
    if (rules) {
      const updatedRowClassRules =
        objectMap(
          rules,
          (v) => function(params) {
            return expression.apply(params.node.data, v)
          }
        )

      this._applyChange("rowClassRules", updatedRowClassRules);
    }
  }


  set gridOptions(options) {
    let globalEventListener = this.globalEventListener.bind(this);

    let mergedOptions = Object.assign(options, this._preInitAgGridAttributes)

    // Can only be instantiated once
    if (!this._initialised) {
      // prevent instantiating multiple grids
      let gridParams = { globalEventListener };
      this.api = createGrid(this, mergedOptions, gridParams);

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
    return ComponentUtil.ALL_PROPERTIES.concat(setterProperties).map(
      (property) => property.toLowerCase()
    );
  }

  set columnState(state) {
    this.api.applyColumnState({ state: state, applyOrder: true });
  }

  set disableResizeOnScroll(disabled) {
    this._addEventHandler(
      "onBodyScrollEnd",
      "disableResizeOnScroll",
      function(params) {
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
      function(params) {
        if (sizeToFit) params.api.sizeColumnsToFit();
      }
    );
  }

  set rowData(data) {
    this._applyChange("rowData", data);

    if (data == []) {
      this.api.showNoRowsOverlay();
    }
  }

  set selectedIds(selectedIds) {
    if (selectedIds.length == 0) {
      this.api.deselectAll();
    } else {
      this.api.forEachNode(function(node) {
        const selected = selectedIds.includes(node.id);
        node.setSelected(selected);
      });
    }
  }

  set columnDefs(defs) {
    function applyCallbacks(def) {
      // This is a group column def
      if (def.children) {
        return {
          ...def,
          children: def.children.map(applyCallbacks)
        }
      } else {
        return {
          ...def,
          editable: (params) => expression.apply(params.node.data, def.editable),
          cellClassRules: objectMap(
            def.cellClassRules,
            (v) => (params) => expression.apply(params.node.data, v)
          ),
        };
      }
    }
    this.api.updateGridOptions({ columnDefs: defs.map(applyCallbacks) });
  }

  set getContextMenuItems(data) {
    const prepareContextAction = (item, params) => {
      if (typeof item === "string") return item;
      // Create a copy that we update to retain the configuration on the `item`.
      let actionItem = { ...item };

      if (typeof item.actionName === "string") {
        actionItem.action = () => {
          const contextMenuEvent = new CustomEvent("contextActionClicked", {
            detail: {
              action: item.actionName,
              data: params.node.data,
            },
          });

          this.dispatchEvent(contextMenuEvent);
        };
      }

      actionItem.subMenu =
        item.subMenu && item.subMenu.length > 0
          ? item.subMenu.map((item) => prepareContextAction(item))
          : null;

      if (typeof item.disabledCallback === "object") {
        actionItem.disabled = expression.apply(
          params.node.data,
          item.disabledCallback
        );
      } else {
        actionItem.disabled = item.disabledCallback;
      }

      actionItem.cssClasses = item.cssClasses.flatMap(
        ({ cssClasses, condition }) => {
          if (typeof condition === "boolean" && condition) return cssClasses;
          if (expression.apply(params.node.data, condition)) return cssClasses;
          return [];
        }
      );

      return actionItem;
    };

    this._applyChange("getContextMenuItems", (params) =>
      data.map((item) => prepareContextAction(item, params))
    );
  }

  _applyChange(propertyName, newValue) {
    this.api.setGridOption(propertyName, newValue);
  }

  _addEventHandler(eventName, type, callback) {
    let collection = this._events[eventName] || {};
    collection[type] = callback;

    this._events = collection;

    this.api.setGridOption(eventName, function(args) {
      Object.values(collection).map((event) => event(args));
    });
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
        this._applyChange(gridPropertyName, parsedNewValue);
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
    const self = this;

    let gridOptions = {
      readOnlyEdit: true,
      components: {
        ...cellEditor,
        appRenderer,
        dateRangeFilter,
        appEditor,
      },

      aggFuncs: CUSTOM_AGGREGATIONS,
      getMainMenuItems: (params) => {
        // Override the default resetColumns actions to additionally trigger an explicit column state change event on the webcomponent
        let defaultItems = params.defaultItems.filter(
          (item) => item != "resetColumns"
        );

        const localeTextFunc =
          params.api.navigationService.localeService.getLocaleTextFunc();

        // Original implemenation of the "resetColumns" actions
        // https://github.com/ag-grid/ag-grid/blob/latest/grid-enterprise-modules/menu/src/menu/menuItemMapper.ts#L155
        defaultItems.push({
          name: localeTextFunc("resetColumns", "Reset Columns"),
          action: function() {
            const changeEvent = columnStateChangedEvent(
              { type: "resetColumns" },
              []
            );

            self.dispatchEvent(changeEvent);
            return params.columnApi.columnModel.resetColumnState("contextMenu");
          },
        });

        return defaultItems;
      },

      isRowSelectable: (params) => {
        return !!params.data && params.data.rowCallbackValues.isRowSelectable;
      },

      onCellEditRequest: function(e) {
        let newData = Object.assign({}, e.data);
        newData[e.column.colId] = e.newValue;
        const editEvent = new CustomEvent("editRequest", {
          detail: {
            data: newData,
            oldValue: e.oldValue,
            newValue: e.newValue,
            field: e.colDef.field
          }
        });
        self.dispatchEvent(editEvent);
      },

      onSelectionChanged: function(event) {
        const nodes = event.api.getSelectedNodes();
        const selectionEvent = new CustomEvent("selectionChanged", {
          detail: { nodes },
        });
        self.dispatchEvent(selectionEvent);
      },
    };

    if (this.loadAttribute("customRowId")) {
      gridOptions.getRowId = function(params) {
        return params.data.rowCallbackValues.rowId;
      };
    }

    this.gridOptions = gridOptions;

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
      "onColumnVisible",
      "onColumnPinned",
      "onColumnRowGroupChanged",
      "onColumnValueChanged",
    ];
    const _this = this;

    columnEvents.map((event) =>
      this._addEventHandler(event, "columnEvents", function(params) {
        // column events should only dispatched when finished is set
        if (params.finished === false) { return }

        const stateChangeEvent = columnStateChangedEvent(
          params,
          params.api.getColumnState()
        );

        _this.dispatchEvent(stateChangeEvent);
      })
    );
  }

  _broadcastFilterState() {
    const filterEvents = ["onFilterChanged"];
    const _this = this;

    filterEvents.map((event) =>
      this._addEventHandler(event, "filterEvents", function(params) {
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

function objectMap(obj, fn) {
  return Object.fromEntries(
    Object.entries(obj).map(([k, v], i) => [k, fn(v, k, i)])
  );
}

export default class ElmAgGrid {
  constructor({ apps = {}, aggregations = {} } = {}) {
    window.ElmAgGridComponentRegistry = apps;
    CUSTOM_AGGREGATIONS = aggregations;

    customElements.define("ag-grid", AgGrid);
  }
}

function columnStateChangedEvent(params, columnState) {
  return new CustomEvent("columnStateChanged", {
    detail: {
      event: params,
      columnState: columnState,
    },
  });
}
