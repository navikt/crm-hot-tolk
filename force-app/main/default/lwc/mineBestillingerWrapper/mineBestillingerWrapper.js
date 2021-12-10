import { LightningElement, track, wire } from 'lwc';
import getRequestList from '@salesforce/apex/HOT_RequestListContoller.getRequestList';
import { CurrentPageReference } from 'lightning/navigation';

export default class MineBestillingerWrapper extends LightningElement {
    isRequestList = true;
    isRequestDetails = false;
    isWorkOrderDetails = false;
    @track urlStateParameters;

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.urlStateParameters = currentPageReference.state;
            console.log(JSON.stringify(this.urlStateParameters));
            console.log(JSON.stringify(this.urlStateParameters.id));
            this.setParametersBasedOnUrl();
        }
    }
    setParametersBasedOnUrl() {
        this.isRequestList = this.urlStateParameters.id === undefined;
        this.isRequestDetails = this.urlStateParameters.id !== undefined;
        this.isWorkOrderDetails = false; //this.urlStateParameters.id;
    }

    @track columns = [
        {
            name: 'Name',
            type: 'String'
        },
        {
            name: 'UserName__c',
            type: 'String'
        },
        {
            name: 'Status__c',
            type: 'String'
        }
    ];

    @track requests = [];
    wiredRequestsResult;
    @wire(getRequestList)
    wiredRequest(result) {
        this.wiredRequestsResult = result;
        if (result.data) {
            this.requests = [...result.data];
            this.template.querySelector('c-record-list').showRecords(this.requests);
        }
    }

    goToRecordDetails(result) {
        console.log('Navigating to: ' + result.detail);
        let refresh =
            window.location.protocol + '//' + window.location.host + window.location.pathname + '?id=' + result.detail;
        window.history.pushState({ path: refresh }, '', refresh);
        this.isRequestList = false;
        this.isRequestDetails = true;
    }
}
