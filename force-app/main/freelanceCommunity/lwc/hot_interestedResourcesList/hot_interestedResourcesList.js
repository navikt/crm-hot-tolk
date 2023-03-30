import { LightningElement, wire, track, api } from 'lwc';
import getInterestedResources from '@salesforce/apex/HOT_InterestedResourcesListController.getInterestedResources';
import retractInterest from '@salesforce/apex/HOT_InterestedResourcesListController.retractInterest';
import getServiceResource from '@salesforce/apex/HOT_Utility.getServiceResource';
import { refreshApex } from '@salesforce/apex';
import { columns, mobileColumns, iconByValue } from './columns';
import { defaultFilters, compare } from './filters';
import { formatRecord } from 'c/datetimeFormatter';
import addComment from '@salesforce/apex/HOT_InterestedResourcesListController.addComment';
import readComment from '@salesforce/apex/HOT_InterestedResourcesListController.readComment';
import getComments from '@salesforce/apex/HOT_InterestedResourcesListController.getComments';

export default class Hot_interestedResourcesList extends LightningElement {
    @track columns = [];
    @track filters = [];
    @track iconByValue = iconByValue;
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
        const eventToSend = new CustomEvent('sendrecords', { detail: this.initialInterestedResources });
        this.dispatchEvent(eventToSend);
    }
    sendDetail() {
        const eventToSend = new CustomEvent('senddetail', { detail: this.isDetails });
        this.dispatchEvent(eventToSend);
    }

    setPreviousFiltersOnRefresh() {
        if (sessionStorage.getItem('interestedfilters')) {
            this.applyFilter({
                detail: { filterArray: JSON.parse(sessionStorage.getItem('interestedfilters')), setRecords: true }
            });
            sessionStorage.removeItem('interestedfilters');
        }
        this.sendFilters();
    }

    disconnectedCallback() {
        // Going back with browser back or back button on mouse forces page refresh and a disconnect
        // Save filters on disconnect to exist only within the current browser tab
        sessionStorage.setItem('interestedfilters', JSON.stringify(this.filters));
    }

    renderedCallback() {
        this.setPreviousFiltersOnRefresh();
    }

    connectedCallback() {
        this.setColumns();
        refreshApex(this.wiredInterestedResourcesResult);
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

    noInterestedResources = false;
    initialInterestedResources = [];
    @track records = [];
    @track allInterestedResourcesWired = [];
    wiredInterestedResourcesResult;
    @wire(getInterestedResources)
    wiredInterestedResources(result) {
        this.wiredInterestedResourcesResult = result;
        if (result.data) {
            this.noInterestedResources = this.allInterestedResourcesWired.length === 0;
            this.error = undefined;
            this.allInterestedResourcesWired = [...result.data];
            this.noInterestedResources = this.allInterestedResourcesWired.length === 0;
            let tempRecords = [];
            for (let record of result.data) {
                tempRecords.push(formatRecord(Object.assign({}, record), this.datetimeFields));
            }
            this.records = tempRecords;
            this.initialInterestedResources = [...this.records];
            this.refresh();
        } else if (result.error) {
            this.error = result.error;
            this.allInterestedResourcesWired = undefined;
        }
    }

    refresh() {
        this.filters = defaultFilters();
        //this.goToRecordDetails({ detail: { Id: this.recordId } });
        this.sendRecords();
        this.sendFilters();
        this.applyFilter({ detail: { filterArray: this.filters, setRecords: true } });
    }

    datetimeFields = [
        {
            name: 'StartAndEndDate',
            type: 'datetimeinterval',
            start: 'ServiceAppointmentStartTime__c',
            end: 'ServiceAppointmentEndTime__c'
        },
        { name: 'WorkOrderCanceledDate__c', type: 'date' },
        { name: 'HOT_ReleaseDate__c', type: 'date' }
    ];

    @track interestedResource;
    isDetails = false;
    isSeries = false;
    showTable = true;
    goToRecordDetails(result) {
        this.template.querySelector('.serviceAppointmentDetails').classList.remove('hidden');
        this.template.querySelector('.serviceAppointmentDetails').focus();
        this.interestedResource = undefined;
        let recordId = result.detail.Id;
        this.recordId = recordId;
        this.isDetails = !!this.recordId;
        for (let interestedResource of this.records) {
            if (recordId === interestedResource.Id) {
                this.interestedResource = interestedResource;
            }
        }
        this.isNotRetractable = this.interestedResource?.Status__c !== 'Påmeldt';
        this.fixComments();
        this.updateURL();
        if (this.interestedResource?.IsNewComment__c) {
            readComment({ interestedResourceId: this.interestedResource?.Id });
        }
    }

    @api recordId;
    updateURL() {
        let baseURL =
            window.location.protocol + '//' + window.location.host + window.location.pathname + '?list=interested';
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
        return { id: recordIdToReturn, tab: 'interested' };
    }

    sendComment() {
        let interestedResourceId = this.interestedResource.Id;
        let newComment = this.template.querySelector('.newComment').value;
        addComment({ interestedResourceId, newComment }).then(() => {
            refreshApex(this.wiredInterestedResourcesResult);
            this.template.querySelector('.newComment').value = '';
            this.fixComments();
        });
    }
    filteredRecordsLength = 0;
    @api
    applyFilter(event) {
        let setRecords = event.detail.setRecords;
        this.filters = event.detail.filterArray;

        let filteredRecords = [];
        let records = this.initialInterestedResources;
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

    @track prevComments = '';
    fixComments() {
        getComments({ interestedResourceId: this.recordId }).then((result) => {
            this.prevComments = '';
            console.log(result.Comments__c);
            if (result.Comments__c != undefined || result.Comments__c != '') {
                this.prevComments = result.Comments__c.split('\n\n');
            } else {
                this.prevComments = '';
            }
        });
    }
    isNotRetractable = false;
    retractInterest() {
        retractInterest({ interestedResourceId: this.interestedResource.Id }).then(() => {
            refreshApex(this.wiredInterestedResourcesResult);
            this.interestedResource.Status__c = 'Tilbaketrukket påmelding';
            let newNumberOfInterestedResources = Number(this.interestedResource.NumberOfInterestedResources__c) - 1;
            this.interestedResource.NumberOfInterestedResources__c = newNumberOfInterestedResources;
            this.isNotRetractable = true;
        });
    }
    closeModal() {
        this.template.querySelector('.serviceAppointmentDetails').classList.add('hidden');
    }
}
