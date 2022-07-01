import { LightningElement, wire, track, api } from 'lwc';
import getOpenServiceAppointments from '@salesforce/apex/HOT_OpenServiceAppointmentListController.getOpenServiceAppointments';
import createInterestedResources from '@salesforce/apex/HOT_OpenServiceAppointmentListController.createInterestedResources';
import getServiceResource from '@salesforce/apex/HOT_Utility.getServiceResource';
import { columns, mobileColumns } from './columns';
import { refreshApex } from '@salesforce/apex';
import { defaultFilters, compare } from './filters';
import { openServiceAppointmentFieldLabels } from 'c/hot_fieldLabels';
import { formatRecord } from 'c/datetimeFormatter';
import { formatRecordDetails } from 'c/hot_recordDetails';
import EarliestStartTime from '@salesforce/schema/ServiceAppointment.EarliestStartTime';
import DueDate from '@salesforce/schema/ServiceAppointment.DueDate';

export default class Hot_openServiceAppointments extends LightningElement {
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
            this.error = undefined;
            this.allServiceAppointmentsWired = [...result.data];
            this.noServiceAppointments = this.allServiceAppointmentsWired.length === 0;
            let tempRecords = [];
            for (let record of result.data) {
                tempRecords.push(formatRecord(Object.assign({}, record), this.datetimeFields));
            }
            this.records = tempRecords;
            this.initialServiceAppointments = [...this.records];
        } else if (result.error) {
            this.error = result.error;
            this.allServiceAppointmentsWired = undefined;
        }
    }

    datetimeFields = [
        { name: 'StartAndEndDate', type: 'datetimeinterval', start: 'EarliestStartTime', end: 'DueDate' },
        { name: 'HOT_DeadlineDate__c', type: 'date' },
        { name: 'HOT_ReleaseDate__c', type: 'date' }
    ];

    @track serviceAppointment;
    isDetails = false;
    isSeries = false;
    showTable = true;
    goToRecordDetails(result) {
        this.checkedServiceAppointments = this.template.querySelector('c-table').getCheckedRows();
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

    @track checkedServiceAppointments = [];
    registerInterest() {
        this.checkedServiceAppointments = this.template.querySelector('c-table').getCheckedRows();
        if (this.checkedServiceAppointments.length > 0) {
            let comments = [];
            this.template.querySelectorAll('.comment-field').forEach((element) => {
                comments.push(element.value);
            });
            createInterestedResources({
                serviceAppointmentIds: this.checkedServiceAppointments,
                comments: comments
            }).then(() => {
                this.closeModal();
                refreshApex(this.wiredAllServiceAppointmentsResult);
            });
        }
    }

    @track serviceAppointmentCommentDetails = [];
    sendInterest() {
        console.log('sending interest');
        this.checkedServiceAppointments = [];
        this.serviceAppointmentCommentDetails = [];
        try {
            this.template
                .querySelector('c-table')
                .getCheckedRows()
                .forEach((row) => {
                    this.checkedServiceAppointments.push(row);
                    this.serviceAppointmentCommentDetails.push(
                        formatRecordDetails(
                            this.getRecord(row),
                            openServiceAppointmentFieldLabels.getSubFields('comment')
                        )
                    );
                });
        } catch (error) {
            console.log(error);
        }
        console.log('showing');
        let commentPage = this.template.querySelector('.commentPage');
        commentPage.classList.remove('hidden');
        commentPage.focus();
        console.log('!!!!!!!!!!!!!');
    }

    closeModal() {
        this.template.querySelector('.commentPage').classList.add('hidden');
    }

    getRecord(id) {
        for (let record of this.records) {
            if (record.Id === id) {
                return record;
            }
        }
        return null;
    }
}
