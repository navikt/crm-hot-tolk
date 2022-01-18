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
                if (value.name !== 'All records') {
                    temp.value.push(value);
                }
            });
            arr.push(temp);
        });
        this.filterArray = arr;
    }

    isOpen = false;
    @api
    openFilters() {
        this.isOpen = !this.isOpen;
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
        let filterindex = event.currentTarget.dataset.filterindex;
        event.detail.forEach((element, index) => {
            this.filterArray[filterindex].value[index].value = element.checked;
            this.filterArray[filterindex].value[index].checked = element.checked;
        });
    }

    handleDateChange(event) {
        let filterindex = event.currentTarget.dataset.filterindex;
        let valueindex = event.currentTarget.dataset.valueindex;
        let localTimeValue = this.template.querySelectorAll('c-input')[valueindex].getValue();
        localTimeValue = new Date(localTimeValue).toLocaleString();
        localTimeValue = localTimeValue.substring(0, localTimeValue.length - 10);
        this.filterArray[filterindex].value[valueindex].localTimeValue = localTimeValue;
        this.filterArray[filterindex].value[valueindex].value = event.detail;
    }

    removeFilter(event) {
        event.stopPropagation();
        let filterindex = event.currentTarget.dataset.filterindex;
        let valueindex = event.currentTarget.dataset.valueindex;
        this.filterArray[filterindex].value[valueindex].value = false;
    }

    overlayContainerClick(event) {
        event.stopPropagation();
    }

    overlayClick() {
        this.closeFilters();
    }
    closeFilters() {
        this.isOpen = false;
    }
}
