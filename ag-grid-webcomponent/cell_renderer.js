export default {
  booleanCellRenderer: function (params) {
    let div = document.createElement("div");
    div.style.display = "flex";
    div.style.height = "100%";
    div.style.justifyContent = "center";
    div.style.alignItems = "center";

    let input = document.createElement("input");
    input.type = "checkbox";
    input.checked = params.value;

    // check editable state of column and assign it to the checkbox
    const editable = params.colDef.editable;
    input.disabled = !editable;

    input.addEventListener("click", function () {
      params.setValue(!params.value);
    });

    div.appendChild(input);
    return div;
  },
};
