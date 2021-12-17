import { LightningElement, api, track } from 'lwc';

export default class ListFilters extends LightningElement {
    @api header;
    @api activeFilters;
    @api filters;
    @track filterArray = [];

    connectedCallback() {
        let arr = [];
        this.filters.forEach((element, filterindex) => {
            let temp = { ...element };
            temp.filterindex = filterindex;
            temp.value = [];
            element.value.forEach((val, valueindex) => {
                let value = { ...val };
                value.valueindex = valueindex;
                temp.value.push(value);
            });
            arr.push(temp);
        });
        this.filterArray = arr;
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
        let filterindex = event.currentTarget.dataset.filterindex;
        let valueindex = event.currentTarget.dataset.valueindex;
        this.filterArray[filterindex].value[valueindex].value = false;
        // remove filter
    }
}
