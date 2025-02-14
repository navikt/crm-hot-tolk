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
            // Lag en kopi av objektet
            const newInterestedResource = { ...this.interestedResource };
            newInterestedResource.Status__c = 'Tilbaketrukket påmelding';
            newInterestedResource.NumberOfInterestedResources__c =
                Number(newInterestedResource.NumberOfInterestedResources__c) - 1;
            // Sett den oppdaterte kopien tilbake til propertyen
            this.interestedResource = newInterestedResource;
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
                    this.closeModal();
                } else {
                    createThreadInterpreter({ recordId: this.interestedResource.Id })
                        .then((result) => {
                            this.navigateToThread(result.Id);
                            this.closeModal();
                        })
                        .catch((error) => {
                            console.error(error);
                        });
                }
            });
        } else {
            getThreadDispatcherIdSA({ saId: this.interestedResource.ServiceAppointment__c }).then((result) => {
                if (result != '') {
                    this.threadId = result;
                    this.navigateToThread(this.threadId);
                    this.closeModal();
                } else {
                    createThreadInterpreter({ recordId: this.interestedResource.ServiceAppointment__c })
                        .then((result) => {
                            this.navigateToThread(result.Id);
                            this.closeModal();
                        })
                        .catch((error) => {
                            console.error(error);
                        });
                }
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
