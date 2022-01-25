function BooleanEditor() {}

BooleanEditor.prototype.init = function(params) {
  this.container = document.createElement('div')
  this.value = params.value
  params.stopEditing()
}
BooleanEditor.prototype.getGui = function() {
  return this.container
}

BooleanEditor.prototype.afterGuiAttached = function() {}

BooleanEditor.prototype.getValue = function() {
  return this.value
}

BooleanEditor.prototype.destroy = function() {}

BooleanEditor.prototype.isPopup = function() {
  return true
}

export default BooleanEditor
