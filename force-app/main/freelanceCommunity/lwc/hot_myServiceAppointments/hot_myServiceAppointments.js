import { LightningElement, wire, track, api } from 'lwc';
import getMyServiceAppointments from '@salesforce/apex/HOT_MyServiceAppointmentListController.getMyServiceAppointments';
import getServiceAppointment from '@salesforce/apex/HOT_MyServiceAppointmentListController.getServiceAppointment';
import getServiceResource from '@salesforce/apex/HOT_Utility.getServiceResource';

import { columns, mobileColumns } from './columns';
import { defaultFilters, compare } from './filters';
import { formatRecord } from 'c/datetimeFormatter';
import { refreshApex } from '@salesforce/apex';

export default class Hot_myServiceAppointments extends LightningElement {
    @track columns = [];
    @track isEditButtonDisabled = false;
    @track isCancelButtonHidden = true;
    @track isEditButtonHidden = false;
    @track flowfeedback;
    @track isFlowFeedback;
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
        this.setColumns();
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
    @wire(getServiceResource)
    wiredServiceresource(result) {
        if (result.data) {
            this.serviceResource = result.data;
        }
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
            this.records = tempRecords;
            this.initialServiceAppointments = [...this.records];
            this.refresh();
        } else if (result.error) {
            this.error = result.error;
            this.allMyServiceAppointmentsWired = undefined;
        }
    }

    refresh() {
        this.filters = defaultFilters();
        this.goToRecordDetails({ detail: { Id: this.recordId } });
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
    goToRecordDetails(result) {
        window.scrollTo(0, 0);
        let today = new Date();
        this.serviceAppointment = undefined;
        this.interestedResource = undefined;
        let recordId = result.detail.Id;
        this.recordId = recordId;
        this.isDetails = !!this.recordId;
        this.isEditButtonHidden = false;
        this.isCancelButtonHidden = true;
        for (let serviceAppointment of this.records) {
            if (recordId === serviceAppointment.Id) {
                this.serviceAppointment = serviceAppointment;
                this.interestedResource = serviceAppointment?.InterestedResources__r[0];
                let duedate = new Date(this.serviceAppointment.DueDate);
                if (this.serviceAppointment.Status == 'Completed') {
                    this.isEditButtonDisabled = true;
                }
            }
        }
        this.updateURL();
        this.sendDetail();
    }

    @api recordId;
    updateURL() {
        let baseURL = window.location.protocol + '//' + window.location.host + window.location.pathname + '?list=my';
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
        this.isflow = false;
        this.isEditButtonDisabled = false;
        this.isFlowFeedback = false;
        this.flowfeedback = '';
        this.sendDetail();
        return { id: recordIdToReturn, tab: 'my' };
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
    changeStatus() {
        this.isflow = true;
        this.isEditButtonDisabled = true;
        this.isCancelButtonHidden = false;
        this.isDetails = true;
        this.isEditButtonHidden = true;
    }
    cancelStatusFlow() {
        this.isflow = false;
        this.isEditButtonDisabled = false;
        this.isCancelButtonHidden = true;
        this.isDetails = true;
        this.isEditButtonHidden = false;
    }
    get flowVariables() {
        return [
            {
                name: 'recordId',
                type: 'String',
                value: this.recordId
            }
        ];
    }
    handleStatusChange(event) {
        console.log('handleStatusChange', event.detail);
        if (event.detail.interviewStatus == 'FINISHED') {
            getServiceAppointment({
                recordId: this.recordId
            }).then((data) => {
                console.log(data.Status);
                if (data.Status == 'Completed') {
                    this.isFlowFeedback = true;
                    this.flowfeedback =
                        'Det er ikke mulig å oppdatere statusen etter at oppdraget er satt til Dekket. Kontakt formidler for å gi ytterligere informasjon om oppdraget.';
                    this.isflow = false;
                    this.isCancelButtonHidden = true;
                }
                if (data.Status == 'Canceled') {
                    this.isFlowFeedback = true;
                    this.flowfeedback = 'Oppdraget er avlyst';
                    this.isflow = false;
                    this.isCancelButtonHidden = true;
                }
            });
            refreshApex(this.wiredMyServiceAppointmentsResult);
        }
    }
}
