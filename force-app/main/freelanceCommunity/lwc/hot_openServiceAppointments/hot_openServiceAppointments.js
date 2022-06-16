import { LightningElement, wire, track, api } from 'lwc';
import getOpenServiceAppointments from '@salesforce/apex/HOT_OpenServiceAppointmentListController.getOpenServiceAppointments';
import getServiceResource from '@salesforce/apex/HOT_Utility.getServiceResource';
import { columns, mobileColumns } from './columns';
import { refreshApex } from '@salesforce/apex';

export default class Hot_openServiceAppointments extends LightningElement {
    @track columns = [];
    setColumns() {
        if (window.screen.width > 576) {
            this.columns = columns;
        } else {
            this.columns = mobileColumns;
        }
    }

    @track serviceResource;
    @track serviceResourceId;
    @wire(getServiceResource)
    wiredServiceresource(result) {
        if (result.data) {
            this.serviceResource = result.data;
            this.serviceResourceId = this.serviceResource.Id;
        }
    }

    noServiceAppointments = true;
    @track allServiceAppointmentsWired;
    @track allServiceAppointments;
    wiredAllServiceAppointmentsWiredResult;
    @wire(getOpenServiceAppointments)
    wiredAllServiceAppointmentsWired(result) {
        this.wiredAllServiceAppointmentsWiredResult = result;
        if (result.data) {
            this.allServiceAppointmentsWired = result.data;
            this.noServiceAppointments = this.allServiceAppointmentsWired.length === 0;
            this.error = undefined;
            this.setDateFormats();
        } else if (result.error) {
            this.error = result.error;
            this.allServiceAppointmentsWired = undefined;
        }
    }

    setDateFormats() {
        let tempServiceAppointments = [];
        for (let i = 0; i < this.allServiceAppointmentsWired.length; i++) {
            let tempRec = Object.assign({}, this.allServiceAppointmentsWired[i]);
            tempRec.DueDate = this.setDateFormat(this.allServiceAppointmentsWired[i].DueDate);
            tempRec.EarliestStartTime = this.setDateFormat(this.allServiceAppointmentsWired[i].EarliestStartTime);
            tempRec.HOT_DeadlineDate__c = this.allServiceAppointmentsWired[i].HOT_DeadlineDate__c.replaceAll('-', '.').split('.').reverse().join('.');
            tempRec.HOT_ReleaseDate__c = this.allServiceAppointmentsWired[i].HOT_ReleaseDate__c.replaceAll('-', '.').split('.').reverse().join('.');
            tempServiceAppointments[i] = tempRec;
        }
        this.allServiceAppointments = tempServiceAppointments;
    }

    setDateFormat(value) {
        value = new Date(value);
        value = value.toLocaleString();
        value = value.substring(0, value.length - 3);
        return value;
    }

    connectedCallback() {
        this.setColumns();
        refreshApex(this.wiredAllServiceAppointmentsWiredResult);
    }

    @track serviceAppointment;
    isServiceAppointmentDetails = false;
    goToRecordDetails(result) {
        window.scrollTo(0, 0);
        let recordId = result.detail.Id;
        this.urlStateParameterId = recordId;
        this.isServiceAppointmentDetails = this.urlStateParameterId !== '';
        for (let serviceAppointment of this.allServiceAppointments) {
            if (recordId === serviceAppointment.Id) {
                this.serviceAppointment = serviceAppointment;
            }
        }
        this.updateURL();
    }

    @track urlStateParameterId = '';
    updateURL() {
        let baseURL = window.location.protocol + '//' + window.location.host + window.location.pathname;
        if (this.urlStateParameterId !== '') {
            baseURL += '?list=open' + '&id=' + this.urlStateParameterId;
        }
        window.history.pushState({ path: baseURL }, '', baseURL);
    }

    @api goBack() {
        let recordIdToReturn = this.urlStateParameterId;
        this.urlStateParameterId = '';
        this.isServiceAppointmentDetails = false;
        return {id: recordIdToReturn, tab: 'open'};
    }
}