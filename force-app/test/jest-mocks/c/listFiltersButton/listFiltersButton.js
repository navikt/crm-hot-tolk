import { LightningElement, api } from 'lwc';

export default class ListFiltersButton extends LightningElement {
    @api header;
    @api filters = [];
    @api filteredRecordsLength;

    @api
    setFilteredRecordsLength(filteredRecordsLength) {
        this.filteredRecordsLength = filteredRecordsLength;
    }

    handleApply() {
        this.dispatchEvent(
            new CustomEvent('applyfilter', {
                detail: { filterArray: this.filters, setRecords: true }
            })
        );
    }
}
