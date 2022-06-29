import { LightningElement, wire, track, api } from 'lwc';
import getMyServiceAppointments from '@salesforce/apex/HOT_MyServiceAppointmentListController.getMyServiceAppointments';
import getServiceResource from '@salesforce/apex/HOT_Utility.getServiceResource';
import { columns, mobileColumns } from './columns';
import { defaultFilters, compare } from './filters';

export default class Hot_myServiceAppointments extends LightningElement {
    @track columns = [];
    setColumns() {
        if (window.screen.width > 576) {
            this.columns = columns;
        } else {
            this.columns = mobileColumns;
        }
    }

    @api getFilters() {
        return this.filters;
    }
    @track filters = [];
    connectedCallback() {
        this.setColumns();
        this.filters = defaultFilters();
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
            this.allMyServiceAppointmentsWired = result.data;
            this.noServiceAppointments = this.allMyServiceAppointmentsWired.length === 0;
            this.error = undefined;
            this.setDateFormats();
        } else if (result.error) {
            this.error = result.error;
            this.allMyServiceAppointmentsWired = undefined;
        }
    }

    setDateFormats() {
        var tempServiceAppointments = [];
        for (var i = 0; i < this.allMyServiceAppointmentsWired.length; i++) {
            let tempRec = Object.assign({}, this.allMyServiceAppointmentsWired[i]);
            tempRec.DueDate = this.setDateFormat(this.allMyServiceAppointmentsWired[i].DueDate);
            tempRec.EarliestStartTime = this.setDateFormat(this.allMyServiceAppointmentsWired[i].EarliestStartTime);
            tempServiceAppointments[i] = tempRec;
        }
        this.records = tempServiceAppointments;
        this.initialServiceAppointments = [...this.records];
    }

    setDateFormat(value) {
        value = new Date(value);
        value = value.toLocaleString();
        value = value.substring(0, value.length - 3);
        return value;
    }

    @track serviceAppointment;
    isDetails = false;
    isSeries = false;
    showTable = true;
    goToRecordDetails(result) {
        window.scrollTo(0, 0);
        let recordId = result.detail.Id;
        this.urlStateParameterId = recordId;
        this.isDetails = this.urlStateParameterId !== '';
        for (let serviceAppointment of this.records) {
            if (recordId === serviceAppointment.Id) {
                this.serviceAppointment = serviceAppointment;
            }
        }
        this.isSeries = this.serviceAppointment.HOT_IsSerieoppdrag__c;
        this.showTable = (this.isSeries && this.urlStateParameterId !== '') || this.urlStateParameterId === '';
        if (this.isSeries) {
            let tempRecords = [];
            for (let record of this.records) {
                if (record.HOT_RequestNumber__c == this.serviceAppointment.HOT_RequestNumber__c) {
                    tempRecords.push(record);
                }
            }
            this.records = [...tempRecords];
        }
        this.updateURL();
    }

    @track urlStateParameterId = '';
    updateURL() {
        let baseURL = window.location.protocol + '//' + window.location.host + window.location.pathname;
        if (this.urlStateParameterId !== '') {
            baseURL += '?list=my' + '&id=' + this.urlStateParameterId;
        }
        window.history.pushState({ path: baseURL }, '', baseURL);
    }

    @api goBack() {
        let recordIdToReturn = this.urlStateParameterId;
        this.urlStateParameterId = '';
        this.isDetails = false;
        this.showTable = true;
        this.records = [...this.initialServiceAppointments];
        return { id: recordIdToReturn, tab: 'my' };
    }
}
