import { LightningElement, wire, track, api } from 'lwc';
import getInterestedResources from '@salesforce/apex/HOT_InterestedResourcesListController.getInterestedResources';
import getServiceResource from '@salesforce/apex/HOT_Utility.getServiceResource';
import { refreshApex } from '@salesforce/apex';
import { columns, mobileColumns, iconByValue } from './columns';
import { defaultFilters, compare } from './filters';
import { formatRecord } from 'c/datetimeFormatter';
import addComment from '@salesforce/apex/HOT_InterestedResourcesListController.addComment';
import readComment from '@salesforce/apex/HOT_InterestedResourcesListController.readComment';

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
        window.scrollTo(0, 0);
        let recordId = result.detail.Id;
        this.urlStateParameterId = recordId;
        this.isDetails = this.urlStateParameterId !== '';
        for (let interestedResource of this.records) {
            if (recordId === interestedResource.Id) {
                this.interestedResource = interestedResource;
            }
        }
        this.updateURL();
        this.sendDetail();
        if (this.interestedResource.IsNewComment__c) {
            readComment({ interestedResourceId: this.interestedResource.Id });
        }
    }

    @track urlStateParameterId = '';
    updateURL() {
        let baseURL = window.location.protocol + '//' + window.location.host + window.location.pathname;
        if (this.urlStateParameterId !== '') {
            baseURL += '?list=interested' + '&id=' + this.urlStateParameterId;
        }
        window.history.pushState({ path: baseURL }, '', baseURL);
    }

    @api goBack() {
        let recordIdToReturn = this.urlStateParameterId;
        this.urlStateParameterId = '';
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
}
