import { LightningElement, api, track } from 'lwc';

export default class DesktopFilters extends LightningElement {
    @api filters;
    @track filterArray = [];

    connectedCallback() {
        console.log('this.filters: ', JSON.stringify(this.filters));
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

    applyFilter() {
        console.log('desktopfilters applyfilter');
        const eventToSend = new CustomEvent('applyfilter', { detail: this.filterArray });
        this.dispatchEvent(eventToSend);
    }

    handleDateChange(event) {
        let filterindex = event.currentTarget.dataset.filterindex;
        let valueindex = event.currentTarget.dataset.valueindex;
        let localTimeValue = this.template.querySelectorAll('c-input')[valueindex].getValue();
        localTimeValue = new Date(localTimeValue).toLocaleString();
        localTimeValue = localTimeValue.substring(0, localTimeValue.length - 10);
        this.filterArray[filterindex].value[valueindex].localTimeValue = localTimeValue;
        this.filterArray[filterindex].value[valueindex].value = event.detail;
        this.applyFilter();
    }

    handlePicklistChange(event) {
        console.log('handlePicklistChange: ', JSON.stringify(event.detail));
        let filterindex = event.currentTarget.dataset.filterindex;
        console.log('filterindex: ', filterindex);
        let valueindex = this.filterArray[filterindex].value.indexOf(event.detail.name);
        this.filterArray[filterindex].value[valueindex].value = this.applyFilter();
    }
}
