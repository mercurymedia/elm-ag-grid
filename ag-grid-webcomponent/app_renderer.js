/**
 * Implements a cellRenderer for AgGrid to use an Elm application for the cell.
 *
 * https://www.ag-grid.com/javascript-data-grid/component-cell-renderer/#cell-renderer-component
 */
class AppRenderer {
  /**
   * Gets called once before the renderer is used.
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

  /**
   * Allows to refresh the Elm application by sending new params through
   * the `componentRefresh` port. Refresh is skipped if the port is not implemented.
   * @param {*} params updated params
   * @returns true, to tell the grid we refreshed successfully
   */
  refresh(params) {
    // Notify component via port, if implemented
    if (this.application?.ports?.componentRefresh) {
      this.application.ports.componentRefresh.send(params);
    }

    return true;
  }
}

export default AppRenderer;
