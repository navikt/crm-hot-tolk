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
            this.setParametersBasedOnUrl();
        }
    }
    setParametersBasedOnUrl() {
        this.isRequestList = this.urlStateParameters.id === undefined;
        this.isRequestDetails = this.urlStateParameters.id !== undefined;
        this.isWorkOrderDetails = false; //this.urlStateParameters.id;
        this.record = this.getRecord(this.urlStateParameters.id);
    }

    @track record;
    getRecord(recordId) {
        for (let request of this.requests) {
            console.log(request);
            if (recordId === request.Id) {
                console.log(request);
                return request;
            }
        }
        return { MeetingSteet__c: '', Subject__c: '' };
    }

    @track columns = [
        {
            name: 'Name',
            label: 'Forespørsel',
            type: 'String',
            svg: false
        },
        {
            name: 'UserName__c',
            label: 'Bruker',
            type: 'String',
            svg: false
        },
        {
            name: 'Status__c',
            label: 'Status',
            type: 'String',
            svg: true
        }
    ];

    @track requests = [];
    wiredRequestsResult;
    @wire(getRequestList)
    wiredRequest(result) {
        this.wiredRequestsResult = result;
        if (result.data) {
            this.requests = [...result.data];
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

    goBack(event) {
        let refresh = window.location.protocol + '//' + window.location.host + window.location.pathname;
        window.history.pushState({ path: refresh }, '', refresh);
        this.isRequestList = this.isRequestDetails;
        this.isRequestDetails = this.isWorkOrderDetails;
        this.isWorkOrderDetails = false;
    }
}
