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
    @track interestedResources;
    @track interestedResourcesFiltered;
    wiredInterestedResourcesResult;
    @wire(getInterestedResources)
    wiredInterestedResources(result) {
        this.wiredInterestedResourcesResult = result;
        if (result.data) {
            this.interestedResources = result.data;
            this.noInterestedResources = this.interestedResources.length === 0;
            this.error = undefined;
            this.setDateFormats();
        } else if (result.error) {
            this.error = result.error;
            this.interestedResources = undefined;
        }
    }
    setDateFormats() {
        var tempInterestedResources = [];
        for (var i = 0; i < this.interestedResources.length; i++) {
            let tempRec = Object.assign({}, this.interestedResources[i]);
            tempRec.ServiceAppointmentEndTime__c = this.setDateFormat(this.interestedResources[i].ServiceAppointmentEndTime__c);
            tempRec.ServiceAppointmentStartTime__c = this.setDateFormat(this.interestedResources[i].ServiceAppointmentStartTime__c);
            tempInterestedResources[i] = tempRec;
        }
        this.interestedResourcesFiltered = tempInterestedResources;
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
