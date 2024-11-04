import LightningModal from 'lightning/modal';
import { api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import retractInterest from '@salesforce/apex/HOT_InterestedResourcesListController.retractInterest';
import getThreadDispatcherId from '@salesforce/apex/HOT_InterestedResourcesListController.getThreadDispatcherId';
import getThreadDispatcherIdSA from '@salesforce/apex/HOT_InterestedResourcesListController.getThreadDispatcherIdSA';
import createThreadInterpreter from '@salesforce/apex/HOT_MessageHelper.createThreadInterpreter';

export default class Hot_interestedResourcesInfoModal extends NavigationMixin(LightningModal) {
    @track hasAccess = true;
    @track isDetails = true;
    @track isGoToThreadButtonDisabled = false;

    @api interestedResource;
    @api isNotRetractable;
    @api serviceResource;

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
    goToInterestedResourceThread() {
        this.isGoToThreadButtonDisabled = true;
        if (
            this.interestedResource.Status__c != 'Assigned' &&
            this.interestedResource.Status__c != 'Tildelt' &&
            this.interestedResource.Status__c != 'Reserved' &&
            this.interestedResource.Status__c != 'Reservert'
        ) {
            getThreadDispatcherId({ interestedResourceId: this.interestedResource.Id }).then((result) => {
                if (result != '') {
                    this.threadId = result;
                    this.navigateToThread(this.threadId);
                } else {
                    createThreadInterpreter({ recordId: this.interestedResource.Id })
                        .then((result) => {
                            this.navigateToThread(result.Id);
                        })
                        .catch((error) => {
                            console.error(error);
                        });
                }
                this.closeModal();
            });
        } else {
            getThreadDispatcherIdSA({ saId: this.interestedResource.ServiceAppointment__c }).then((result) => {
                if (result != '') {
                    this.threadId = result;
                    this.navigateToThread(this.threadId);
                } else {
                    createThreadInterpreter({ recordId: this.interestedResource.ServiceAppointment__c })
                        .then((result) => {
                            this.navigateToThread(result.Id);
                        })
                        .catch((error) => {
                            console.error(error);
                        });
                }
                this.closeModal();
            });
        }
    }
    closeModal() {
        this.close();
    }
    navigateToThread(recordId) {
        const baseUrl = '/samtale-frilans';
        const attributes = `recordId=${recordId}&from=mine-oppdrag&list=interested&interestedRecordId=${this.interestedResource.Id}`;
        const url = `${baseUrl}?${attributes}`;

        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: url
            }
        });
    }
}
