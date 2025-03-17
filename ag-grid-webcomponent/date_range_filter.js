class DateRangeFilter {
    init(params) {
        this.eGui = document.createElement('div');
        this.eGui.innerHTML = "<button>Filter</button>";
        this.params = params;
        this.filterState = false;

        this.eGui.querySelector('button').addEventListener('click', () => {
            this.filterState = !this.filterState;
            this.updateFilter();
        });
    }
    doesFilterPass(params) {
        const runtime = this.params.valueGetter(params);
        console.log('runtime',runtime); // Log the runtime value
        // Implement your filter logic here using the runtime value
        return false;
    }
    isFilterActive() {
        return this.filterState;
    }
    updateFilter() {
        this.params.filterChangedCallback();
    }
    getModel() {
        return null;
    }
    setModel(model) {
    }
    getGui() {
        return this.eGui;
    }
}

export default DateRangeFilter;
  