import { LightningElement, wire, track, api } from 'lwc';
import getOpenServiceAppointments from '@salesforce/apex/HOT_OpenServiceAppointmentListController.getOpenServiceAppointments';
import createInterestedResources from '@salesforce/apex/HOT_OpenServiceAppointmentListController.createInterestedResources';
import getServiceResource from '@salesforce/apex/HOT_Utility.getServiceResource';
import { columns, mobileColumns } from './columns';
import { refreshApex } from '@salesforce/apex';
import { defaultFilters, compare, setDefaultFilters } from './filters';
import { formatRecord } from 'c/datetimeFormatter';

export default class Hot_openServiceAppointments extends LightningElement {
    @track columns = [];
    setColumns() {
        if (window.screen.width > 576) {
            this.columns = columns;
        } else {
            this.columns = mobileColumns;
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
    sendCheckedRows() {
        this.showSendInterest = this.checkedServiceAppointments.length > 0;
        this.sendInterestButtonLabel = 'Meld interesse til ' + this.checkedServiceAppointments.length + ' oppdrag';
        const eventToSend = new CustomEvent('sendcheckedrows', { detail: this.checkedServiceAppointments });
        this.dispatchEvent(eventToSend);
    }
    sendInterestButtonLabel = '';
    setPreviousFiltersOnRefresh() {
        if (localStorage.getItem('openfilters')) {
            this.applyFilter({
                detail: { filterArray: JSON.parse(localStorage.getItem('openfilters')), setRecords: true }
            });
            localStorage.removeItem('openfilters');
        }
        this.sendFilters();
    }
    setCheckedRowsOnRefresh() {
        if (sessionStorage.getItem('checkedrows') && !this.isDetails) {
            this.checkedServiceAppointments = JSON.parse(sessionStorage.getItem('checkedrows'));
            sessionStorage.removeItem('checkedrows');
        }
        this.sendCheckedRows();
    }

    disconnectedCallback() {
        // Going back with browser back or back button on mouse forces page refresh and a disconnect
        // Save filters on disconnect to exist only within the current browser tab
        localStorage.setItem('openfilters', JSON.stringify(this.filters));
        sessionStorage.setItem('checkedrows', JSON.stringify(this.checkedServiceAppointments));
    }

    renderedCallback() {
        this.setPreviousFiltersOnRefresh();
        this.setCheckedRowsOnRefresh();
        localStorage.setItem('checkedrowsSavedForRefresh', JSON.stringify(this.checkedServiceAppointments));
        localStorage.setItem('filterSavedForRefresh', JSON.stringify(this.filters));
        localStorage.removeItem('openfilters');
    }

    @track filters = [];
    connectedCallback() {
        if (localStorage.getItem('checkedrowsSavedForRefresh')) {
            this.checkedServiceAppointments = JSON.parse(localStorage.getItem('checkedrowsSavedForRefresh'));
            localStorage.removeItem('checkedrowsSavedForRefresh');
        }

        this.setColumns();
        refreshApex(this.wiredAllServiceAppointmentsResult);
        this.breadcrumbs = [
            {
                label: 'Tolketjenesten',
                href: ''
            },
            {
                label: 'oppdrag',
                href: 'mine-oppdrag'
            }
        ];
    }

    @track serviceResource;
    @track serviceResourceId;
    @wire(getServiceResource)
    wiredServiceresource(result) {
        if (result.data) {
            this.serviceResource = result.data;
            this.serviceResourceId = this.serviceResource.Id;
            this.filters = setDefaultFilters(this.serviceResource.HOT_PreferredRegions__c);
            if (this.wiredAllServiceAppointmentsResult !== null) {
                this.refresh();
            }
        }
    }

    noServiceAppointments = false;
    initialServiceAppointments = [];
    @track records = [];
    @track allServiceAppointmentsWired = [];
    wiredAllServiceAppointmentsResult;
    @wire(getOpenServiceAppointments)
    wiredAllServiceAppointmentsWired(result) {
        this.wiredAllServiceAppointmentsResult = result;
        if (result.data) {
            this.error = undefined;
            this.allServiceAppointmentsWired = [...result.data];
            this.noServiceAppointments = this.allServiceAppointmentsWired.length === 0;
            let tempRecords = [];
            for (let record of result.data) {
                tempRecords.push(formatRecord(Object.assign({}, record), this.datetimeFields));
            }
            this.records = tempRecords;
            this.initialServiceAppointments = [...this.records];
            if (this.serviceResource !== null) {
                this.refresh();
            }
        } else if (result.error) {
            this.error = result.error;
            this.allServiceAppointmentsWired = undefined;
        }
    }

    refresh() {
        // this.filters = defaultFilters();
        this.sendRecords();
        this.sendFilters();
        this.sendCheckedRows();
        // this.applyFilter({ detail: { filterArray: this.filters, setRecords: true } });
    }

    datetimeFields = [
        { name: 'StartAndEndDate', type: 'datetimeinterval', start: 'EarliestStartTime', end: 'DueDate' },
        { name: 'HOT_DeadlineDate__c', type: 'date' },
        { name: 'HOT_ReleaseDate__c', type: 'date', newName: 'ReleaseDate' }
    ];

    @track serviceAppointment;
    isDetails = false;
    isSeries = false;
    seriesRecords = [];
    showTable = true;
    goToRecordDetails(result) {
        this.serviceAppointment = undefined;
        this.seriesRecords = [];
        let recordId = result.detail.Id;
        this.recordId = recordId;
        this.isDetails = !!this.recordId;
        for (let serviceAppointment of this.records) {
            if (recordId === serviceAppointment.Id) {
                this.serviceAppointment = serviceAppointment;
                this.isSeries = this.serviceAppointment.HOT_IsSerieoppdrag__c;
            }
        }
        for (let serviceAppointment of this.records) {
            if (this.serviceAppointment?.HOT_Request__c === serviceAppointment?.HOT_Request__c) {
                this.seriesRecords.push(serviceAppointment);
            }
        }
        this.isSeries = this.seriesRecords.length <= 1 ? false : true;
        this.showServiceAppointmentDetails();
    }
    showServiceAppointmentDetails() {
        this.template.querySelector('.serviceAppointmentDetails').classList.remove('hidden');
        this.template.querySelector('.serviceAppointmentDetails').focus();
    }

    @api recordId;
    updateURL() {
        let baseURL = window.location.protocol + '//' + window.location.host + window.location.pathname + '?list=open';
        if (this.recordId) {
            baseURL += '&id=' + this.recordId;
        }
        window.history.pushState({ path: baseURL }, '', baseURL);
    }

    @api goBack() {
        let recordIdToReturn = this.recordId;
        this.recordId = undefined;
        this.isDetails = false;
        this.showTable = true;
        this.sendDetail();
        return { id: recordIdToReturn, tab: 'open' };
    }

    errorMessage = '';
    spin = false;
    @track checkedServiceAppointments = [];
    registerInterest() {
        if (this.sendInterestAll) {
            this.checkedServiceAppointments = [];
            this.serviceAppointmentCommentDetails.forEach((element) => {
                this.checkedServiceAppointments.push(element.Id);
            });
        } else {
            this.checkedServiceAppointments = this.template.querySelector('c-table').getCheckedRows();
        }
        if (this.checkedServiceAppointments.length === 0) {
            this.closeModal();
            return;
        }
        let comments = [];
        this.template.querySelectorAll('.comment-field').forEach((element) => {
            comments.push(element.value);
        });
        this.spin = true;
        this.template.querySelector('.comment-details').classList.add('hidden');
        this.template.querySelector('.send-inn-button').classList.add('hidden');
        this.template.querySelector('.submitted-loading').classList.remove('hidden');
        createInterestedResources({
            serviceAppointmentIds: this.checkedServiceAppointments,
            comments: comments
        })
            .then(() => {
                this.spin = false;
                this.template.querySelector('.submitted-loading').classList.add('hidden');
                this.template.querySelector('.submitted-true').classList.remove('hidden');
                this.template.querySelector('c-table').unsetCheckboxes();
                this.checkedServiceAppointments = [];
                this.sendInterestedButtonDisabled = true; // Set button to disabled when interest is sent successfully
                let currentFilters = this.filters;
                if (this.sendInterestAll) {
                    this.sendInterestAllComplete = true;
                    this.applyFilter({ detail: { filterArray: currentFilters, setRecords: true } });
                }
                refreshApex(this.wiredAllServiceAppointmentsResult).then(() => {
                    // Since refreshApex causes the wired methods to run again, the default filters will override current filters.
                    // Apply previous filter
                    this.applyFilter({ detail: { filterArray: currentFilters, setRecords: true } });
                });
            })
            .catch((error) => {
                this.spin = false;
                this.showSendInterest = true;
                this.template.querySelector('.submitted-loading').classList.add('hidden');
                this.template.querySelector('.submitted-error').classList.remove('hidden');
                this.errorMessage = JSON.stringify(error);
                this.sendInterestAll = false;
            });
    }

    handleRowChecked(event) {
        this.checkedServiceAppointments = event.detail.checkedRows;
        this.sendCheckedRows();
    }

    showSendInterest = false;
    @track serviceAppointmentCommentDetails = [];
    sendInterest() {
        this.hideSubmitIndicators();
        this.showCommentSection();
        this.checkedServiceAppointments = [];
        this.serviceAppointmentCommentDetails = [];
        try {
            this.template
                .querySelector('c-table')
                .getCheckedRows()
                .forEach((row) => {
                    this.checkedServiceAppointments.push(row);
                    this.serviceAppointmentCommentDetails.push(this.getRecord(row));
                });
        } catch (error) {
            console.log(error);
        }
        if (this.checkedServiceAppointments.length === 0) {
            this.showSendInterest = false;
            return;
        }
        this.showSendInterest = false;
        this.showCommentPage();
    }

    sendInterestAllComplete = false;
    sendInterestAll = false;
    sendInterestSeries() {
        this.template.querySelector('.serviceAppointmentDetails').classList.add('hidden');
        this.hideSubmitIndicators();
        this.showCommentSection();
        this.serviceAppointmentCommentDetails = [];
        this.sendInterestAll = true;
        this.serviceAppointmentCommentDetails.push(...this.seriesRecords);
        this.showCommentPage();
    }

    showCommentPage() {
        this.template.querySelector('.commentPage').classList.remove('hidden');
        this.template.querySelector('.commentPage').focus();
    }

    hideSubmitIndicators() {
        this.template.querySelector('.submitted-error').classList.add('hidden');
        this.template.querySelector('.submitted-loading').classList.add('hidden');
        this.template.querySelector('.submitted-true').classList.add('hidden');
    }

    closeModal() {
        if (this.sendInterestAllComplete) {
            refreshApex(this.wiredAllServiceAppointmentsResult).then(() => {
                // Since refreshApex causes the wired methods to run again, the default filters will override current filters.
                // Apply previous filter
                this.applyFilter({ detail: { filterArray: currentFilters, setRecords: true } });
            });
            this.goBack();
        }
        this.sendInterestAllComplete = false;
        this.sendInterestAll = false;
        this.template.querySelector('.commentPage').classList.add('hidden');
        this.template.querySelector('.serviceAppointmentDetails').classList.add('hidden');
    }

    showCommentSection() {
        this.template.querySelector('.comment-details').classList.remove('hidden');
        this.template.querySelector('.send-inn-button').classList.remove('hidden');
    }

    getRecord(id) {
        for (let record of this.records) {
            if (record.Id === id) {
                return record;
            }
        }
        return null;
    }

    filteredRecordsLength = 0;
    @api
    applyFilter(event) {
        let setRecords = event.detail.setRecords;
        this.filters = event.detail.filterArray;
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

        if (setRecords) {
            this.records = filteredRecords;
        }
        return this.filteredRecordsLength;
    }
}
