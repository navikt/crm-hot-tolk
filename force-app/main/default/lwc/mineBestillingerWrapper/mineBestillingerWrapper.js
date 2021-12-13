import { LightningElement, track, wire } from 'lwc';
import getMyWorkOrdersNew from '@salesforce/apex/HOT_WorkOrderListController.getMyWorkOrdersNew';
import { CurrentPageReference } from 'lightning/navigation';

export default class MineBestillingerWrapper extends LightningElement {
    isList = true;
    isRequestDetails = false;
    isWorkOrderDetails = false;
    @track urlStateParameters;

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.urlStateParameters = currentPageReference.state;
            this.setParametersBasedOnUrl();
        }
    }
    setParametersBasedOnUrl() {
        this.isList = this.urlStateParameters.id === undefined;
        this.isRequestDetails = this.urlStateParameters.id !== undefined;
        this.isWorkOrderDetails = false; //this.urlStateParameters.id;
        this.record = this.getRecord(this.urlStateParameters.id);
    }

    @track record;
    getRecord(recordId) {
        for (let record of this.records) {
            if (recordId === record.Id) {
                return record;
            }
        }
        return { Address: '', Subject: '' };
    }

    @track columns = [
        {
            name: 'StartDate',
            label: 'Start tid',
            type: 'String',
            svg: false
        },
        {
            name: 'Status',
            label: 'Status',
            type: 'String',
            svg: true
        },
        {
            name: 'Subject',
            label: 'Emne',
            type: 'String',
            svg: false
        }
    ];

    @track records = [];
    wiredMyWorkOrdersNewResult;
    @wire(getMyWorkOrdersNew)
    wiredMyWorkOrdersNew(result) {
        this.wiredMyWorkOrdersNewResult = result;
        if (result.data) {
            this.records = [...result.data];
            this.record = this.getRecord(this.urlStateParameters.id);
        }
    }

    goToRecordDetails(result) {
        let record = result.detail;
        let recordId = record.HOT_Request__r.IsSerieoppdrag__c ? record.HOT_Request__c : record.Id;
        let refresh =
            window.location.protocol + '//' + window.location.host + window.location.pathname + '?id=' + recordId;
        window.history.pushState({ path: refresh }, '', refresh);
        this.isList = false;
        this.isRequestDetails = record.HOT_Request__r.IsSerieoppdrag__c;
        this.isWorkOrderDetails = !record.HOT_Request__r.IsSerieoppdrag__c;
    }

    goBack(event) {
        let refresh = window.location.protocol + '//' + window.location.host + window.location.pathname;
        window.history.pushState({ path: refresh }, '', refresh);
        this.isList = this.isRequestDetails;
        this.isRequestDetails = this.isWorkOrderDetails;
        this.isWorkOrderDetails = false;
    }
}
