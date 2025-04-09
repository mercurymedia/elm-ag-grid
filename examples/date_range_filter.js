class DateRangeFilter {
    init(params) {
        this.params = params;
        this.eGui = document.createElement('div');
        this.eGui.style = `
            padding:5px;
        `
        this.eGui.innerHTML = `
            <div class="ag-filter-body-wrapper ag-simple-filter-body-wrapper" ref="eFilterBody" style="max-height: 969px;">
                <div class="ag-picker-field ag-labeled ag-label-align-left ag-select ag-filter-select" role="presentation">
                    <div ref="eLabel" class="ag-label ag-hidden" aria-hidden="true" role="presentation" id="ag-4327-label"></div>
                    <div ref="eDisplayField" class="ag-picker-field-display" id="ag-4327-display">Filter runtimes not passing this date:</div>
                </div>
                <div class="ag-filter-body" role="presentation" aria-hidden="false">
                    <div role="presentation" class="ag-labeled ag-label-align-left ag-text-field ag-input-field ag-filter-from ag-filter-filter" aria-hidden="false">
                        <div ref="eLabel" class="ag-input-field-label ag-label ag-hidden ag-text-field-label" aria-hidden="true" role="presentation" id="ag-4329-label"></div>
                        <div ref="eWrapper" class="ag-wrapper ag-input-wrapper ag-text-field-input-wrapper" role="presentation">
                            <input ref="eInput" class="ag-input-field-input ag-text-field-input" type="date" id="filterDate" tabindex="0" placeholder="Filter..." aria-label="Filter Value">
                        </div>
                    </div>
                    <div role="presentation" class="ag-labeled ag-label-align-left ag-text-field ag-input-field ag-filter-to ag-filter-filter ag-hidden" aria-hidden="true">
                        <div ref="eLabel" class="ag-input-field-label ag-label ag-hidden ag-text-field-label" aria-hidden="true" role="presentation" id="ag-4330-label"></div>
                        <div ref="eWrapper" class="ag-wrapper ag-input-wrapper ag-text-field-input-wrapper" role="presentation">
                            <input ref="eInput" id="filterDate" class="ag-input-field-input ag-text-field-input" type="text" id="ag-4330-input" tabindex="0" placeholder="To" aria-label="Filter to Value">
                        </div>
                    </div>
                </div>
            </div>
            <div class="ag-filter-apply-panel">
                <button type="button" ref="clearFilterButton" id="clearFilter" class="ag-button ag-standard-button ag-filter-apply-panel-button">Clear</button>
            </div>
        `;

        this.filterDate = null;
    
        this.eGui.querySelector('#filterDate').addEventListener('change', () => {
          this.filterDate = this.eGui.querySelector('#filterDate').value;
          this.updateFilter();
        });

        this.eGui.querySelector('#clearFilter').addEventListener('click', () => {
            this.filterDate = null;
            this.eGui.querySelector('#filterDate').value = '';
            this.updateFilter();
        });
      }
    doesFilterPass(params) {
        const getterFn = this.params.colDef.filterValueGetter 
            ? new Function("data", this.params.colDef.filterValueGetter) 
            : this.defaultValueGetter.bind(this);
            
        const runtimeArray = getterFn(params.data);

        // Looks like: [ [dateFrom1,dateTo1], [dateFrom2,dateTo2] ]
        const filterDate = new Date(this.filterDate);


        let allResults = []
        
        if (runtimeArray.length === 0) {
            return false;
        }
        else {
            for (let i = 0; i < runtimeArray.length; i++) {
                const [dateFrom, dateTo] = runtimeArray[i];
                allResults.push(dateFrom <= filterDate && filterDate <= dateTo);
            }
            return allResults.includes(true);
        }

    }
    isFilterActive() {
        return this.filterDate !== null && this.filterDate !== '';
    }
    updateFilter() {
        this.params.filterChangedCallback();
    }
    getModel() {
        return this.filterDate ? { filterDate: this.filterDate, filterType: 'dateRange' } : null;
    }
    setModel(model) {
        if (model) {
            this.filterDate = model.filterDate;
            this.eGui.querySelector('#filterDate').value = model.filterDate;
        }
    }
    getGui() {
        return this.eGui;
    }
    defaultValueGetter(params) {
        const rawDataString = params[this.params.column.colId];
    
        if (!rawDataString) {
            return null;
        }
    
        return rawDataString.split(",")
            .map(dateRange => dateRange.split(" - ")
                .map(dateString => {
                    const date = new Date(dateString.trim());
                    date.setHours(0, 0, 0, 0);
                    return date;
                })
            );
    }
}

export default DateRangeFilter;
  