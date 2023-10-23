/**
 * Implements a cellEditor for AgGrid to use an Elm application for the cell.
 *
 * https://www.ag-grid.com/javascript-data-grid/component-cell-editor/#cell-editor-example
 */
class AppEditor {
  /**
   * Gets called once the editor is used.
   * Loads the Elm application into a `DocumentFragment`.
   * @param {*} params Contains encoded user and table data
   */
  init(params) {
    this.eGui = new DocumentFragment();

    const component = this.component(params);
    const mountedElement = document.createElement("div");

    this.eGui.appendChild(mountedElement);

    // Initialize application after the node has been appended to the `DocumentFragment`
    if (component) {
      this.application = component.init({
        node: mountedElement,
        flags: params,
      });

      // Set initial editor value according to the cell value
      this.currentValue = params.value;

      const _this = this;
      // Listen for populated changes to the current value
      this.application?.ports?.currentValue.subscribe((value) => {
        _this.currentValue = value;
      });
    }
  }

  /**
   * Retrieve the component by name from the `ElmAgGridComponentRegistry`.
   * @param {*} params cellRenderer params
   * @returns component object
   */
  component(params) {
    const component = window.ElmAgGridComponentRegistry[params.componentName];
    if (component) return component;

    throw `
        \nCouldn't find component '${params.componentName}'.
        \nCheck https://github.com/mercurymedia/elm-ag-grid/tree/main#register-component for further details on registering components.
      `;
  }

  afterGuiAttached() {}

  getValue() {
    return this.currentValue;
  }

  isCancelAfterEnd() {}

  isPopup() {
    return true;
  }

  /**
   * Returns the `DocumentFragment` in which the Elm application is loaded.
   * @returns `DocumentFragment` with the Elm application
   */
  getGui() {
    return this.eGui;
  }

  /**
   * Called after rendering is finished to perform cleanup.
   */
  destroy() {}
}

export default AppEditor;
