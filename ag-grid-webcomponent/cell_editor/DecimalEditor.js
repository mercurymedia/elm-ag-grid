export default class DecimalEditor {
  init(params) {
    this.countryCode = params.countryCode;
    this.decimalPlaces = params.decimalPlaces;
    this.type = params.type;

    let [, thousandsSeparator, , , , decimalSeparator] =
      (1111.1).toLocaleString(this.countryCode);

    this.thousandsSeparator = thousandsSeparator;
    this.decimalSeparator = decimalSeparator;
    this.escapedThousandsSep = this.escapeSeparator(this.thousandsSeparator);
    this.escapedDecimalSep = this.escapeSeparator(this.decimalSeparator);

    this.eInput = document.createElement("input");
    this.eInput.value = this.formatValue(params.value);

    this.eInput.addEventListener("keydown", (event) => {
      if (!this.isInputAllowed(event.key)) {
        // ignore invalid characters
        this.eInput.focus();
        if (event.preventDefault) event.preventDefault();
      }
    });

    this.eInput.addEventListener("input", (event) => {
      if (this.formattableInput(event)) {
        const normalizedValue = this.normalizeValue(event.target.value);
        const newValue = this.formatValue(normalizedValue);

        let newSelectionIndex = Math.max(
          0,
          newValue.length -
            event.target.value.length +
            this.eInput.selectionStart
        );

        this.eInput.value = newValue;
        this.eInput.setSelectionRange(newSelectionIndex, newSelectionIndex);
        return;
      }

      // Ignore formatting with invalid value
      // We don't wanna block the user input
      this.eInput.value = event.target.value;
    });
  }

  afterGuiAttached() {
    this.eInput.focus();
  }

  destroy() {}

  getGui() {
    return this.eInput;
  }

  getValue() {
    const number = Number(this.localeParseFloat(this.eInput.value));
    if (isNaN(number)) return null;

    let formattedNumber = number.toFixed(this.decimalPlaces);
    return formattedNumber;
  }

  isCancelAfterEnd() {}

  isPopup() {
    return false;
  }

  // -- Utility functions -- //

  countDecimals(value) {
    if (Math.floor(value) === value) return 0;
    let decimals = value.toString().split(this.decimalSeparator)[1];
    return decimals?.length || 0;
  }

  cursorInLastPosition() {
    return this.eInput.selectionStart == this.eInput.value.length;
  }

  escapeSeparator(value) {
    return value.replace(/[.]/g, "\\$&");
  }

  formattableInput(event) {
    if (!event.target.value) return false;

    if (
      event.data &&
      event.data === "0" &&
      this.cursorInLastPosition() &&
      this.countDecimals(event.target.value) > 0
    ) {
      // Prevent formatting when inputting a zero as finishing decimal
      return false;
    }

    const fixablePattern = new RegExp(
      `^[-]?([${this.escapedThousandsSep}\\d]*)(${this.escapedDecimalSep}[0-9]{1,})?$`
    );

    return fixablePattern.test(event.target.value);
  }

  formatValue(value) {
    if (!value) return null;

    return new Intl.NumberFormat(this.countryCode, {
      style: "decimal",
      maximumFractionDigits: this.decimalPlaces,
    }).format(value);
  }

  invalidDecimalInput() {
    // Disallow adding more values than decimal places are supported

    return (
      this.cursorInLastPosition() &&
      this.eInput.value.indexOf(this.decimalSeparator) >= 0 &&
      this.countDecimals(this.eInput.value) >= this.decimalPlaces
    );
  }

  invalidDecimalSeparatorInput() {
    // Disallow adding another decimal separator

    return (
      this.decimalPlaces == 0 ||
      this.eInput.value.indexOf(this.decimalSeparator) >= 0
    );
  }

  isInputAllowed(char) {
    if (this.isNavigationKey(char)) return true;

    if (this.invalidDecimalInput()) {
      return false;
    }

    if (char == this.decimalSeparator && this.invalidDecimalSeparatorInput()) {
      return false;
    }

    return /[0-9\.,-]/.test(char);
  }

  isNavigationKey(key) {
    return (
      key === "ArrowLeft" ||
      key === "ArrowRight" ||
      key === "ArrowUp" ||
      key === "ArrowDown" ||
      key === "PageDown" ||
      key === "PageUp" ||
      key === "Home" ||
      key === "End" ||
      key === "Escape" ||
      key === "Enter" ||
      key === "Backspace"
    );
  }

  localeParseFloat(input) {
    return parseFloat(this.normalizeValue(input));
  }

  normalizeValue(value) {
    return Array.from(value, (c) =>
      c === this.thousandsSeparator ? "" : c === this.decimalSeparator ? "." : c
    ).join("");
  }
}
