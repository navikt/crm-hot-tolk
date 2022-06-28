import { LightningElement, wire, track, api } from 'lwc';
import getOpenServiceAppointments from '@salesforce/apex/HOT_OpenServiceAppointmentListController.getOpenServiceAppointments';
import createInterestedResources from '@salesforce/apex/HOT_OpenServiceAppointmentListController.createInterestedResources';
import getServiceResource from '@salesforce/apex/HOT_Utility.getServiceResource';
import { columns, mobileColumns } from './columns';
import { refreshApex } from '@salesforce/apex';
import { defaultFilters, compare } from './filters';

export default class Hot_openServiceAppointments extends LightningElement {
    @track columns = [];
    setColumns() {
        if (window.screen.width > 576) {
            this.columns = columns;
        } else {
            this.columns = mobileColumns;
        }
    }

    @track filters = [];
    connectedCallback() {
        this.setColumns();
        refreshApex(this.wiredAllServiceAppointmentsResult);
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
    @track serviceResourceId;
    @wire(getServiceResource)
    wiredServiceresource(result) {
        if (result.data) {
            this.serviceResource = result.data;
            this.serviceResourceId = this.serviceResource.Id;
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
            tempRec.HOT_DeadlineDate__c = this.allServiceAppointmentsWired[i].HOT_DeadlineDate__c.replaceAll('-', '.')
                .split('.')
                .reverse()
                .join('.');
            tempRec.HOT_ReleaseDate__c = this.allServiceAppointmentsWired[i].HOT_ReleaseDate__c.replaceAll('-', '.')
                .split('.')
                .reverse()
                .join('.');
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
            baseURL += '?list=open' + '&id=' + this.urlStateParameterId;
        }
        window.history.pushState({ path: baseURL }, '', baseURL);
    }

    @api goBack() {
        let recordIdToReturn = this.urlStateParameterId;
        this.urlStateParameterId = '';
        this.isDetails = false;
        this.showTable = true;
        this.records = [...this.initialServiceAppointments];
        return { id: recordIdToReturn, tab: 'open' };
    }

    registerInterest() {
        let checkedServiceAppointments = this.template.querySelector('c-table').getCheckedRows();
        if (checkedServiceAppointments.length > 0) {
            let comments = [];
            this.template.querySelectorAll('.comment-field').forEach((element) => {
                comments.push(element.value);
            });
            createInterestedResources({ serviceAppointmentIds: checkedServiceAppointments, comments: comments }).then(
                () => {
                    refreshApex(this.wiredAllServiceAppointmentsResult);
                }
            );
        }
    }
}
