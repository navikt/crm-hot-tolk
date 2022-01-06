import { LightningElement, track, wire } from 'lwc';
import getMyWorkOrdersNew from '@salesforce/apex/HOT_WorkOrderListController.getMyWorkOrdersNew';
import { CurrentPageReference } from 'lightning/navigation';
import { columns, mobileColumns, workOrderColumns, iconByValue } from './columns';
import { defaultFilters } from './filters';
export default class MineBestillingerWrapper extends LightningElement {
    @track filters = [];
    connectedCallback() {
        this.filters = defaultFilters();
        if (window.screen.width > 576) {
            this.columns = columns;
        } else {
            this.columns = mobileColumns;
        }
    }
    isList = true;
    isRequestDetails = false;
    isWorkOrderDetails = false;
    @track urlStateParameters;
    @track columns;
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
                console.log('WorkOrder: ', JSON.stringify(this.workOrder));
                this.workOrder = record;
                this.workOrderStartDate = this.formatDate(this.workOrder.StartDate, true);
                this.workOrderEndDate = this.formatDate(this.workOrder.EndDate, true);
                this.request = record.HOT_Request__r;
                console.log('Request: ', JSON.stringify(this.request));
                this.requestSeriesStartDate = this.formatDate(this.request.SeriesStartDate__c, false);
                this.requestSeriesEndDate = this.formatDate(this.request.SeriesEndDate__c, false);
            }
        }
        if (this.request.Id !== undefined) {
            this.getWorkOrders();
        }
    }

    workOrderStartDate = '';
    workOrderEndDate = '';
    requestSeriesStartDate = '';
    requestSeriesEndDate = '';
    formatDate(dateInput, isWorkOrder) {
        let value = new Date(dateInput);
        value = value.toLocaleString();
        if (isWorkOrder) {
            return value.substring(0, value.length - 3);
        }
        return value.substring(0, value.length - 10);
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
        console.log('Refresh');
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
