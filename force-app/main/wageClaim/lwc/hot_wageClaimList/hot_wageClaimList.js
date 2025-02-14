import { LightningElement, wire, track, api } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getMyWageClaims from '@salesforce/apex/HOT_WageClaimListController.getMyWageClaims';
import { columns, mobileColumns } from './columns';
import { NavigationMixin } from 'lightning/navigation';
import { formatRecord } from 'c/datetimeFormatter';
import { defaultFilters, compare } from './filters';
import HOT_informationModal from 'c/hot_informationModal';
export default class Hot_wageClaimList extends NavigationMixin(LightningElement) {
    @track columns = [];
    @track filters = [];
    setColumns() {
        if (window.screen.width > 576) {
            this.columns = columns;
        } else {
            this.columns = mobileColumns;
        }
    }
    noWageClaims = false;
    @track wageClaims = [];
    @track allWageClaimsWired = [];
    wiredWageClaimsResult;
    @wire(getMyWageClaims)
    wiredWageClaims(result) {
        this.wiredWageClaimsResult = result;
        if (result.data) {
            this.allWageClaimsWired = result.data;
            this.noWageClaims = this.allWageClaimsWired.length === 0;
            this.error = undefined;
            let tempRecords = [];
            for (let record of result.data) {
                tempRecords.push(formatRecord(Object.assign({}, record), this.datetimeFields));
            }
            this.wageClaims = tempRecords;
            this.allWageClaimsWired = this.wageClaims;
            this.refresh();
        } else if (result.error) {
            this.error = result.error;
            this.allWageClaimsWired = undefined;
        }
    }

    refresh() {
        let filterFromSessionStorage = JSON.parse(sessionStorage.getItem('wageClaimSessionFilter'));
        this.filters = filterFromSessionStorage === null ? defaultFilters() : filterFromSessionStorage;
        this.sendRecords();
        this.sendFilters();
        this.applyFilter({ detail: { filterArray: this.filters, setRecords: true } });
    }

    setPreviousFiltersOnRefresh() {
        if (sessionStorage.getItem('wageclaimfilters')) {
            this.applyFilter({
                detail: { filterArray: JSON.parse(sessionStorage.getItem('wageclaimfilters')), setRecords: true }
            });
            sessionStorage.removeItem('wageclaimfilters');
        }
        this.sendFilters();
    }

    disconnectedCallback() {
        // Going back with browser back or back button on mouse forces page refresh and a disconnect
        // Save filters on disconnect to exist only within the current browser tab
        sessionStorage.setItem('wageclaimfilters', JSON.stringify(this.filters));
    }

    renderedCallback() {
        this.setPreviousFiltersOnRefresh();
    }

    getDayOfWeek(date) {
        var jsDate = new Date(date);
        var dayOfWeek = jsDate.getDay();
        var dayOfWeekString;
        switch (dayOfWeek) {
            case 0:
                dayOfWeekString = 'Søndag';
                break;
            case 1:
                dayOfWeekString = 'Mandag';
                break;
            case 2:
                dayOfWeekString = 'Tirsdag';
                break;
            case 3:
                dayOfWeekString = 'Onsdag';
                break;
            case 4:
                dayOfWeekString = 'Torsdag';
                break;
            case 5:
                dayOfWeekString = 'Fredag';
                break;
            case 6:
                dayOfWeekString = 'Lørdag';
                break;
            default:
                dayOfWeekString = '';
        }
        return dayOfWeekString;
    }

    datetimeFields = [{ name: 'StartAndEndDate', type: 'datetimeinterval', start: 'StartTime__c', end: 'EndTime__c' }];

    @track recordId;
    @track showDetails = false;
    @track urlRedirect = false;

    connectedCallback() {
        this.setColumns();
        this.updateURL();
        refreshApex(this.wiredWageClaimsResult);
    }
    closeModal() {
        this.template.querySelector('.serviceAppointmentDetails').classList.add('hidden');
        this.recordId = undefined;
        this.updateURL();
    }
    @track wageClaim;
    isWageClaimDetails = false;
    async goToRecordDetails(result) {
        let recordId = result.detail.Id;
        this.recordId = recordId;
        // Open the modal and wait for it to close.
        await HOT_informationModal.open({
            size: this.getModalSize(),
            recordId: this.recordId,
            type: 'WC',
            fromUrlRedirect: false,
            records: this.wageClaims
        });
        // Update the URL after the modal is closed.
        this.updateURL();
        // Refresh Apex data after modal closure.
        refreshApex(this.wiredWageClaimsResult);
    }

    getModalSize() {
        return window.screen.width < 768 ? 'full' : 'small';
    }

    @api recordId;
    updateURL() {
        let baseURL =
            window.location.protocol + '//' + window.location.host + window.location.pathname + '?list=wageClaim';
        if (this.recordId) {
            baseURL += '&id=' + this.recordId;
        }
        window.history.pushState({ path: baseURL }, '', baseURL);
    }

    @api goBack() {
        this.recordId = undefined;
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                pageName: 'home'
            }
        });
    }

    sendFilters() {
        const eventToSend = new CustomEvent('sendfilters', { detail: this.filters });
        this.dispatchEvent(eventToSend);
    }
    sendRecords() {
        const eventToSend = new CustomEvent('sendrecords', { detail: this.allWageClaimsWired });
        this.dispatchEvent(eventToSend);
    }
    sendDetail() {
        const eventToSend = new CustomEvent('senddetail', { detail: this.isWageClaimDetails });
        this.dispatchEvent(eventToSend);
    }
    filteredRecordsLength = 0;
    @api
    applyFilter(event) {
        let setRecords = event.detail.setRecords;
        this.filters = event.detail.filterArray;
        sessionStorage.setItem('wageClaimSessionFilter', JSON.stringify(this.filters));
        let filteredRecords = [];
        let records = this.allWageClaimsWired;
        for (let record of records) {
            let includeRecord = true;
            for (let filter of this.filters) {
                includeRecord *= compare(filter, record);
            }
            if (includeRecord) {
                filteredRecords.push(record);
            }
        }
        this.filteredRecordsLength = filteredRecords.length;

        if (setRecords) {
            this.wageClaims = filteredRecords;
        }
        return this.filteredRecordsLength;
    }
    handleRefreshRecords() {
        refreshApex(this.wiredWageClaimsResult);
    }
}
