import { LightningElement, wire, track, api } from 'lwc';
import getMyServiceAppointments from '@salesforce/apex/HOT_MyServiceAppointmentListController.getMyServiceAppointments';
import Hot_informationModal from 'c/hot_informationModal';

import { NavigationMixin } from 'lightning/navigation';
import { columns, mobileColumns } from './columns';
import { defaultFilters, compare } from './filters';
import { formatRecord, formatDatetimeinterval } from 'c/datetimeFormatterNorwegianTime';
import { refreshApex } from '@salesforce/apex';
import { getParametersFromURL } from 'c/hot_URIDecoder';

export default class Hot_myServiceAppointments extends NavigationMixin(LightningElement) {
    @track columns = [];
    @track isMobile;
    isGoToThreadButtonDisabled = false;
    isGoToThreadServiceAppointmentButtonDisabled = false;
    isGoToThreadInterpretersButtonDisabled = false;

    get hasResult() {
        return this.records && this.records.length > 0;
    }

    get noServiceAppointments() {
        return (!this.records || this.records.length === 0) && !this.filters?.length;
    }

    get noFilteredRecords() {
        return (!this.records || this.records.length === 0) && this.filters?.length > 0;
    }

    setColumns() {
        if (window.screen.width > 576) {
            this.columns = columns;
            this.isMobile = false;
        } else {
            this.columns = mobileColumns;
            this.isMobile = true;
        }
    }

    sendFilters() {
        const eventToSend = new CustomEvent('sendfilters', { detail: this.filters });
        this.dispatchEvent(eventToSend);
    }
    sendRecords() {
        const eventToSend = new CustomEvent('sendrecords', { detail: this.initialServiceAppointments });
        this.dispatchEvent(eventToSend);
    }
    sendDetail() {
        const eventToSend = new CustomEvent('senddetail', { detail: this.isDetails });
        this.dispatchEvent(eventToSend);
    }

    setPreviousFiltersOnRefresh() {
        if (sessionStorage.getItem('myfilters')) {
            this.applyFilter({
                detail: { filterArray: JSON.parse(sessionStorage.getItem('myfilters')), setRecords: true }
            });
            sessionStorage.removeItem('myfilters');
        }
        this.sendFilters();
    }

    disconnectedCallback() {
        // Going back with browser back or back button on mouse forces page refresh and a disconnect
        // Save filters on disconnect to exist only within the current browser tab
        sessionStorage.setItem('myfilters', JSON.stringify(this.filters));
    }

    renderedCallback() {
        this.setPreviousFiltersOnRefresh();
    }

    @track filters = [];
    connectedCallback() {
        refreshApex(this.wiredMyServiceAppointmentsResult);
        this.setColumns();
        this.getParams();
        this.updateURL();
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

    noServiceAppointments = false;
    initialServiceAppointments = [];
    @track records = [];
    @track allMyServiceAppointmentsWired = [];
    wiredMyServiceAppointmentsResult;
    @wire(getMyServiceAppointments)
    wiredMyServiceAppointments(result) {
        this.wiredMyServiceAppointmentsResult = result;
        if (result.data) {
            let tempRecords = [];
            for (let record of result.data) {
                tempRecords.push(formatRecord(Object.assign({}, record), this.datetimeFields));
            }
            this.allMyServiceAppointmentsWired = tempRecords;
            this.noServiceAppointments = this.allMyServiceAppointmentsWired.length === 0;
            this.error = undefined;
            this.records = tempRecords.map((x) => ({
                ...x,
                startAndEndDateWeekday:
                    formatDatetimeinterval(x.EarliestStartTime, x.DueDate) +
                    ' ' +
                    this.getDayOfWeek(x.EarliestStartTime)
            }));
            this.initialServiceAppointments = [...this.records];
            this.refresh();
        } else if (result.error) {
            this.error = result.error;
            this.allMyServiceAppointmentsWired = undefined;
        }
    }

    refresh() {
        let filterFromSessionStorage = JSON.parse(sessionStorage.getItem('mySessionFilter'));
        this.filters = filterFromSessionStorage === null ? defaultFilters() : filterFromSessionStorage;
        this.sendRecords();
        this.sendFilters();
        this.applyFilter({ detail: { filterArray: this.filters, setRecords: true } });
    }

    datetimeFields = [
        { name: 'StartAndEndDate', type: 'datetimeinterval', start: 'EarliestStartTime', end: 'DueDate' },
        { name: 'ActualStartTime', type: 'datetime' },
        { name: 'ActualEndTime', type: 'datetime' },
        { name: 'HOT_DeadlineDate__c', type: 'date' },
        { name: 'HOT_ReleaseDate__c', type: 'date' }
    ];
    @track serviceAppointment;
    @track interestedResource;

    isDetails = false;
    isflow = false;
    isSeries = false;
    showTable = true;
    @track recordId;
    @track urlRedirect = false;
    @track showDetails = false;

    getModalSize() {
        return window.screen.width < 768 ? 'full' : 'small';
    }

    async goToRecordDetails(result) {
        let recordId = result.detail.Id;
        this.recordId = recordId;
        await Hot_informationModal.open({
            size: 'small',
            recordId: this.recordId,
            type: 'SA',
            fromUrlRedirect: false,
            records: this.records
        });
        refreshApex(this.wiredMyServiceAppointmentsResult);
        this.updateURL();
    }
    goToRecordDetailsFromNotification(saId) {
        let recordId = saId;
        this.recordId = recordId;
        this.showDetails = true;
        this.urlRedirect = true;
        this.updateURL();
        Hot_informationModal.open({
            size: 'small',
            recordId: this.recordId,
            type: 'SA',
            fromUrlRedirect: true,
            records: this.records
        });
    }

    @api recordId;
    updateURL() {
        let baseURL = window.location.protocol + '//' + window.location.host + window.location.pathname + '?list=my';
        if (this.recordId) {
            baseURL += '&id=' + this.recordId;
        }
        window.history.pushState({ path: baseURL }, '', baseURL);
    }
    navigationId = '';
    navigationLevel = '';
    navigationBaseUrl = '';
    navigationBaseList = '';
    getParams() {
        let parsed_params = getParametersFromURL() ?? '';
        if (parsed_params.from == 'mine-varsler' && parsed_params.id != '') {
            this.navigationBaseUrl = parsed_params.from;
            this.goToRecordDetailsFromNotification(parsed_params.id);
        }
    }

    @api goBack() {
        if (this.navigationBaseUrl == 'mine-varsler') {
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    pageName: 'mine-varsler'
                },
                state: {}
            });
        } else {
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    pageName: 'home'
                }
            });
        }
    }
    filteredRecordsLength = 0;
    noFilteredRecords = false;
    @api
    applyFilter(event) {
        let setRecords = event.detail.setRecords;
        this.filters = event.detail.filterArray;
        sessionStorage.setItem('mySessionFilter', JSON.stringify(this.filters));
        let filteredRecords = [];
        let records = this.initialServiceAppointments;
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
        this.noFilteredRecords = this.filteredRecordsLength === 0 && this.filters.length > 0;

        if (setRecords) {
            this.records = filteredRecords;
        }
        return this.filteredRecordsLength;
    }
    handleRefreshRecords() {
        refreshApex(this.wiredMyServiceAppointmentsResult);
    }
}
