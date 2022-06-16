import { LightningElement, wire, track, api } from 'lwc';
import getMyServiceAppointments from '@salesforce/apex/HOT_MyServiceAppointmentListController.getMyServiceAppointments';
import getServiceResource from '@salesforce/apex/HOT_Utility.getServiceResource';
import { columns, mobileColumns } from './columns';

export default class Hot_myServiceAppointments extends LightningElement {
    @track columns = [];
    setColumns() {
        if (window.screen.width > 576) {
            this.columns = columns;
        } else {
            this.columns = mobileColumns;
        }
    }

    connectedCallback() {
        this.setColumns();
    }

    @track serviceResource;
    @wire(getServiceResource)
    wiredServiceresource(result) {
        if (result.data) {
            this.serviceResource = result.data;
        }
    }

    noServiceAppointments = true;
    @track myServiceAppointmentsWired;
    @track myServiceAppointments;
    wiredMyServiceAppointmentsResult;
    @wire(getMyServiceAppointments)
    wiredMyServiceAppointments(result) {
        this.wiredMyServiceAppointmentsResult = result;
        if (result.data) {
            this.myServiceAppointmentsWired = result.data;
            this.noServiceAppointments = this.myServiceAppointmentsWired.length === 0;
            this.error = undefined;
            this.setDateFormats();
        } else if (result.error) {
            this.error = result.error;
            this.myServiceAppointmentsWired = undefined;
        }
    }

    setDateFormats() {
        var tempServiceAppointments = [];
        for (var i = 0; i < this.myServiceAppointmentsWired.length; i++) {
            let tempRec = Object.assign({}, this.myServiceAppointmentsWired[i]);
            tempRec.DueDate = this.setDateFormat(this.myServiceAppointmentsWired[i].DueDate);
            tempRec.EarliestStartTime = this.setDateFormat(this.myServiceAppointmentsWired[i].EarliestStartTime);
            tempServiceAppointments[i] = tempRec;
        }
        this.myServiceAppointments = tempServiceAppointments;
    }

    setDateFormat(value) {
        value = new Date(value);
        value = value.toLocaleString();
        value = value.substring(0, value.length - 3);
        return value;
    }

    @track serviceAppointment;
    isServiceAppointmentDetails = false;
    goToRecordDetails(result) {
        window.scrollTo(0, 0);
        let recordId = result.detail.Id;
        this.urlStateParameterId = recordId;
        this.isServiceAppointmentDetails = this.urlStateParameterId !== '';
        for (let serviceAppointment of this.myServiceAppointments) {
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
            baseURL += '?list=my' + '&id=' + this.urlStateParameterId;
        }
        window.history.pushState({ path: baseURL }, '', baseURL);
    }

    @api goBack() {
        let recordIdToReturn = this.urlStateParameterId;
        this.urlStateParameterId = '';
        this.isServiceAppointmentDetails = false;
        return {id: recordIdToReturn, tab: 'my'};
    }
}
