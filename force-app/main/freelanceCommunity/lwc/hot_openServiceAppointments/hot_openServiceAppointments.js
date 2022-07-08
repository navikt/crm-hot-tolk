import { LightningElement, wire, track, api } from 'lwc';
import getOpenServiceAppointments from '@salesforce/apex/HOT_OpenServiceAppointmentListController.getOpenServiceAppointments';
import createInterestedResources from '@salesforce/apex/HOT_OpenServiceAppointmentListController.createInterestedResources';
import getServiceResource from '@salesforce/apex/HOT_Utility.getServiceResource';
import { columns, mobileColumns } from './columns';
import { refreshApex } from '@salesforce/apex';
import { defaultFilters, compare, setDefaultFilters } from './filters';
import { openServiceAppointmentFieldLabels } from 'c/hot_fieldLabels';
import { formatRecord } from 'c/datetimeFormatter';
import { formatRecordDetails } from 'c/hot_recordDetails';

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

    @track filters = [];
    connectedCallback() {
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
        this.filters = defaultFilters();
        this.sendRecords();
        this.sendFilters();
        this.applyFilter({ detail: { filterArray: this.filters, setRecords: true } });
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
        this.updateURL();
        this.sendDetail();
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
        this.sendDetail();
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
        let commentPage = this.template.querySelector('.commentPage');
        commentPage.classList.remove('hidden');
        commentPage.focus();
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
