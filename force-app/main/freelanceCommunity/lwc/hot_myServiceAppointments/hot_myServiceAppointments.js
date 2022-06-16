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
    @track myServiceAppointments;
    @track myServiceAppointmentsFiltered;
    wiredMyServiceAppointmentsResult;
    @wire(getMyServiceAppointments)
    wiredMyServiceAppointments(result) {
        this.wiredMyServiceAppointmentsResult = result;
        if (result.data) {
            this.myServiceAppointments = result.data;
            this.noServiceAppointments = this.myServiceAppointments.length === 0;
            this.error = undefined;
            this.setDateFormats();
        } else if (result.error) {
            this.error = result.error;
            this.myServiceAppointments = undefined;
        }
    }

    setDateFormats() {
        var tempServiceAppointments = [];
        for (var i = 0; i < this.myServiceAppointments.length; i++) {
            let tempRec = Object.assign({}, this.myServiceAppointments[i]);
            tempRec.DueDate = this.setDateFormat(this.myServiceAppointments[i].DueDate);
            tempRec.EarliestStartTime = this.setDateFormat(this.myServiceAppointments[i].EarliestStartTime);
            tempServiceAppointments[i] = tempRec;
        }
        this.myServiceAppointmentsFiltered = tempServiceAppointments;
    }

    setDateFormat(value) {
        value = new Date(value);
        value = value.toLocaleString();
        value = value.substring(0, value.length - 3);
        return value;
    }
}
