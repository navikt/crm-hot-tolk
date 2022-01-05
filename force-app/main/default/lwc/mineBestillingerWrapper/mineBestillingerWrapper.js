import { LightningElement, track, wire } from 'lwc';
import getMyWorkOrdersNew from '@salesforce/apex/HOT_WorkOrderListController.getMyWorkOrdersNew';
import { CurrentPageReference } from 'lightning/navigation';
import { columns, workOrderColumns, iconByValue } from './columns';
import { defaultFilters } from './filters';
export default class MineBestillingerWrapper extends LightningElement {
    @track filters = [];
    connectedCallback() {
        this.filters = defaultFilters();
    }
    isList = true;
    isRequestDetails = false;
    isWorkOrderDetails = false;
    @track urlStateParameters;

    @track columns = columns;
    @track workOrderColumns = workOrderColumns;
    @track iconByValue = iconByValue;

    @track records = [];
    @track allRecords = [];
    wiredMyWorkOrdersNewResult;
    @wire(getMyWorkOrdersNew)
    wiredMyWorkOrdersNew(result) {
        this.wiredMyWorkOrdersNewResult = result;
        if (result.data) {
            this.records = [...result.data];
            this.allRecords = [...result.data];
            this.refresh();
        }
    }
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.urlStateParameters = { ...currentPageReference.state };
            this.refresh();
        }
    }

    @track request = { MeetingStreet__c: '', Subject__c: '' };
    @track workOrder = { HOT_AddressFormated__c: '', Subject: '' };
    @track workOrders = [];
    getRecords() {
        let recordId = this.urlStateParameters.id;
        for (let record of this.records) {
            if (recordId === record.Id) {
                this.workOrder = record;
                this.request = record.HOT_Request__r;
                console.log('Request: ', this.request);
            }
        }
        if (this.request.Id !== undefined) {
            this.getWorkOrders();
        }
    }
    getWorkOrders() {
        let workOrders = [];
        for (let record of this.records) {
            if (record.HOT_Request__c === this.request.Id) {
                workOrders.push(record);
            }
        }
        this.workOrders = workOrders;
    }

    goToRecordDetails(result) {
        let record = result.detail;
        let recordId = record.Id;
        let level = record.HOT_Request__r.IsSerieoppdrag__c ? 'R' : 'WO';
        if (this.urlStateParameters.level === 'R') {
            level = 'WO';
        }
        this.urlStateParameters.id = recordId;
        this.urlStateParameters.level = level;
        this.refresh();
    }

    goBack() {
        let currentLevel = this.urlStateParameters.level;
        let goThroughRequest = this.workOrder.HOT_Request__r.IsSerieoppdrag__c;
        if (currentLevel === 'WO' && goThroughRequest === true) {
            this.urlStateParameters.level = 'R';
        } else {
            this.urlStateParameters.id = undefined;
            this.urlStateParameters.level = undefined;
        }
        this.refresh();
    }

    refresh() {
        this.getRecords();
        this.updateURL();
        this.updateView();
        this.applyFilter({ detail: this.filters });
    }
    updateView() {
        this.isList = this.urlStateParameters.id === undefined;
        this.isRequestDetails = this.urlStateParameters.level === 'R';
        this.isWorkOrderDetails = this.urlStateParameters.level === 'WO';
    }
    updateURL() {
        let refresh = window.location.protocol + '//' + window.location.host + window.location.pathname;
        if (this.urlStateParameters.id !== undefined && this.urlStateParameters.level !== undefined) {
            refresh += '?id=' + this.urlStateParameters.id + '&level=' + this.urlStateParameters.level;
        }
        window.history.pushState({ path: refresh }, '', refresh);
    }
    applyFilter(event) {
        //console.log('Filters: ', JSON.stringify(event.detail));
        this.filters = event.detail;

        let filteredRecords = [];
        for (let record of this.allRecords) {
            let includeRecord = true;
            for (let filter of this.filters) {
                includeRecord *= filter.compare(record);
            }
            if (includeRecord) {
                filteredRecords.push(record);
            }
        }
        this.records = filteredRecords;
    }
}
