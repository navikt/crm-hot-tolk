import { LightningElement, api, track } from 'lwc';

export default class ListFilters extends LightningElement {
    @api header;
    @api activeFilters;
    @api filters;
    @track filterArray = [];

    connectedCallback() {
        this.filters.forEach((element) => {
            this.filterArray.push({ ...element });
        });
    }

    isOpen = false;
    @api
    openFilters() {
        this.isOpen = true;
    }
    closeFilters() {
        this.isOpen = false;
    }
    applyFilter() {
        const eventToSend = new CustomEvent('applyfilter', { detail: this.filterArray });
        this.dispatchEvent(eventToSend);
        this.closeFilters();
    }
    handleRowClick(event) {
        let chosenFilter = event.currentTarget.dataset.id;
        this.template.querySelectorAll('li.row-element').forEach((element, index) => {
            if (element.dataset.id === chosenFilter) {
                this.filterArray[index].isOpen = !this.filterArray[index].isOpen;
            }
        });
    }
    handleCheckboxChange(event) {
        // update filters
    }
    handleDateChange(event) {
        //update filters
    }

    addFilter(filter) {
        //Add filter
    }
    removeFilter(event) {
        event.stopPropagation();
        let filterName = event.currentTarget.dataset.filter;
        let filterToRemove = event.currentTarget.dataset.id;
        // remove filter
    }
}
