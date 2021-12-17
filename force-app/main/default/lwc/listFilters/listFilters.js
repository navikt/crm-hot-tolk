import { LightningElement, api, track } from 'lwc';

export default class ListFilters extends LightningElement {
    @api header;
    @api activeFilters;
    @api filters;
    @track filterArray = [];

    connectedCallback() {
        let arr = [];
        this.filters.forEach((element) => {
            let temp = { ...element };
            temp.value = [];
            element.value.forEach((val) => {
                let value = { ...val };
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
        let filterindex = event.currentTarget.dataset.filterindex;
        this.filterArray[filterindex].isOpen = !this.filterArray[filterindex].isOpen;
    }
    handleCheckboxChange(event) {
        console.log(JSON.stringify(event.detail));
        let filterindex = event.currentTarget.dataset.filterindex;
        console.log(JSON.stringify(event.currentTarget.dataset));
        event.detail.forEach((element, index) => {
            this.filterArray[filterindex].value[index].value = element.value;
        });
        console.log(JSON.stringify(this.filterArray[filterindex].value));
    }
    handleDateChange(event) {
        let filterindex = event.currentTarget.dataset.filterindex;
        let valueindex = event.currentTarget.dataset.valueindex;
        this.filterArray[filterindex].value[valueindex].value = event.detail;
    }

    removeFilter(event) {
        event.stopPropagation();
        console.log(JSON.stringify(event.currentTarget.dataset));
        let filterindex = event.currentTarget.dataset.filterindex;
        let valueindex = event.currentTarget.dataset.valueindex;
        this.filterArray[filterindex].value[valueindex].value = false;
    }
}
