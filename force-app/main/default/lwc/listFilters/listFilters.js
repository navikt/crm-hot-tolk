import { LightningElement, api, track } from 'lwc';

export default class ListFilters extends LightningElement {
    @api header;
    @api activeFilters;
    @api filters;
    @track filterArray = [];
    @track filterMap = {};

    connectedCallback() {
        this.filters.forEach((element) => {
            this.filterArray.push({ ...element });
            this.filterMap[element.name] = { ...element };
        });
    }

    isOpen = false;
    openFilters() {
        console.log(JSON.stringify(this.filters));
        this.isOpen = true;
    }
    closeFilters() {
        this.isOpen = false;
    }
    applyFilter() {
        this.closeFilters();
        const eventToSend = new CustomEvent('applyfilter', { detail: this.filterArray });
        this.dispatchEvent(eventToSend);
    }
    handleRowClick(event) {
        let chosenFilter = event.currentTarget.dataset.id;
        console.log(chosenFilter);
        this.template.querySelectorAll('li.row-element').forEach((element, index) => {
            if (element.dataset.id === chosenFilter) {
                this.filterArray[index].isOpen = !this.filterArray[index].isOpen;
            }
        });
    }
    handleCheckboxChange(event) {
        let filter = event.currentTarget.dataset.id;
        let checkboxes = event.detail;
        console.log(checkboxes);
        console.log(filter);
    }
    handleDateChange(event) {
        let date = event.detail;
        console.log(date);
    }

    addFilter(filter) {}
    removeFilter(event) {
        let filter = event.currentTarget.dataset.filter;
        let filterName = event.currentTarget.dataset.id;
    }
}
