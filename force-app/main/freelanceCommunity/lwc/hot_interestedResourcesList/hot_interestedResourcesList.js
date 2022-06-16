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

    noInterestedResources = true;
    @track interestedResourcesWired;
    @track interestedResources;
    wiredInterestedResourcesResult;
    @wire(getInterestedResources)
    wiredInterestedResources(result) {
        this.wiredInterestedResourcesResult = result;
        if (result.data) {
            this.interestedResourcesWired = result.data;
            this.noInterestedResources = this.interestedResourcesWired.length === 0;
            this.error = undefined;
            this.setDateFormats();
        } else if (result.error) {
            this.error = result.error;
            this.interestedResourcesWired = undefined;
        }
    }
    setDateFormats() {
        var tempInterestedResources = [];
        for (var i = 0; i < this.interestedResourcesWired.length; i++) {
            let tempRec = Object.assign({}, this.interestedResourcesWired[i]);
            tempRec.ServiceAppointmentEndTime__c = this.setDateFormat(this.interestedResourcesWired[i].ServiceAppointmentEndTime__c);
            tempRec.ServiceAppointmentStartTime__c = this.setDateFormat(this.interestedResourcesWired[i].ServiceAppointmentStartTime__c);
            tempInterestedResources[i] = tempRec;
        }
        this.interestedResources = tempInterestedResources;
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
    isInterestedResourceDetails = false;
    goToRecordDetails(result) {
        window.scrollTo(0, 0);
        let recordId = result.detail.Id;
        this.urlStateParameterId = recordId;
        this.isInterestedResourceDetails = this.urlStateParameterId !== '';
        for (let interestedResource of this.interestedResources) {
            if (recordId === interestedResource.Id) {
                this.interestedResource = interestedResource;
            }
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
        this.isInterestedResourceDetails = false;
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
