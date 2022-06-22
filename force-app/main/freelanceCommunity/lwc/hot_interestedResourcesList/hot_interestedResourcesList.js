import { LightningElement, wire, track, api } from 'lwc';
import getInterestedResources from '@salesforce/apex/HOT_InterestedResourcesListController.getInterestedResources';
import getServiceResource from '@salesforce/apex/HOT_Utility.getServiceResource';
import { refreshApex } from '@salesforce/apex';
//import retractInterests from '@salesforce/apex/HOT_InterestedResourcesListController.retractInterests';
//import addComment from '@salesforce/apex/HOT_InterestedResourcesListController.addComment';
import { columns, mobileColumns } from './columns';

export default class Hot_interestedResourcesList extends LightningElement {
    @track columns = [];
    setColumns() {
        if (window.screen.width > 576) {
            this.columns = columns;
        } else {
            this.columns = mobileColumns;
        }
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
            this.allInterestedResourcesWired = result.data;
            this.noInterestedResources = this.allInterestedResourcesWired.length === 0;
            this.error = undefined;
            this.setDateFormats();
        } else if (result.error) {
            this.error = result.error;
            this.allInterestedResourcesWired = undefined;
        }
    }
    setDateFormats() {
        var tempInterestedResources = [];
        for (var i = 0; i < this.allInterestedResourcesWired.length; i++) {
            let tempRec = Object.assign({}, this.allInterestedResourcesWired[i]);
            tempRec.ServiceAppointmentEndTime__c = this.setDateFormat(this.allInterestedResourcesWired[i].ServiceAppointmentEndTime__c);
            tempRec.ServiceAppointmentStartTime__c = this.setDateFormat(this.allInterestedResourcesWired[i].ServiceAppointmentStartTime__c);
            tempInterestedResources[i] = tempRec;
        }
        this.records = tempInterestedResources;
        this.initialInterestedResources = [...this.records];
    }

    setDateFormat(value) {
        value = new Date(value);
        value = value.toLocaleString();
        value = value.substring(0, value.length - 3);
        return value;
    }

    connectedCallback() {
        this.setColumns();
        refreshApex(this.wiredInterestedResourcesResult);
    }

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
        this.isSeries = this.interestedResource.ServiceAppointment__r.HOT_IsSerieoppdrag__c;
        this.showTable = (this.isSeries && this.urlStateParameterId !== '') || this.urlStateParameterId === '';
        if (this.isSeries) {
            let tempRecords = [];
            for (let record of this.records) {
                if (record.ServiceAppointment__r.HOT_RequestNumber__c == this.interestedResource.ServiceAppointment__r.HOT_RequestNumber__c) {
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
            baseURL += '?list=interested' + '&id=' + this.urlStateParameterId;
        }
        window.history.pushState({ path: baseURL }, '', baseURL);
    }

    @api goBack() {
        let recordIdToReturn = this.urlStateParameterId;
        this.urlStateParameterId = '';
        this.isDetails = false;
        this.showTable = true;
        this.records = [...this.initialInterestedResources];
        return {id: recordIdToReturn, tab: 'interested'};
    }
    /*@track recordId;
    sendComment() {
        let interestedResourceId = this.recordId;
        var newComment = this.template.querySelector('.newComment').value;
        addComment({ interestedResourceId, newComment }).then(() => {
            refreshApex(this.wiredInterestedResourcesResult);
        });
        this.template.querySelector('.ReactModal__Overlay').classList.add('hidden');
    }

    retractInterest() {
        if (this.selectedRows.length > 0) {
            let retractionIds = [];
            for (var i = 0; i < this.selectedRows.length; i++) {
                retractionIds.push(this.selectedRows[i].Id);
            }
            if (confirm('Er du sikker på at du vil tilbaketrekke interesse for valgte oppdrag?')) {
                retractInterests({ retractionIds }).then(() => {
                    refreshApex(this.wiredInterestedResourcesResult);
                });
            }
        } else {
            alert('Velg oppdrag du ønsker å tilbaketrekke interesse for, så trykk på knappen.');
        }
    }*/
}
