import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import hasRegisteredInterest from '@salesforce/apex/HOT_InterestedResourceBannerController.hasRegisteredInterest';
import { APPLICATION_SCOPE, MessageContext, subscribe, unsubscribe } from 'lightning/messageService';
import INTEREST_REGISTERED_CHANNEL from '@salesforce/messageChannel/HOT_ServiceAppointmentInterestRegistered__c';

export default class Hot_serviceAppointmentInterestBanner extends LightningElement {
    @api recordId;

    refreshPromise;
    subscription;

    @wire(hasRegisteredInterest, { serviceAppointmentId: '$recordId' })
    interestState;

    @wire(MessageContext)
    messageContext;

    disconnectedCallback() {
        this.unsubscribeFromInterestRegistered();
    }

    get showBanner() {
        return this.interestState?.data === true;
    }

    renderedCallback() {
        this.subscribeToInterestRegistered();
    }

    subscribeToInterestRegistered() {
        if (this.subscription || !this.messageContext) {
            return;
        }

        this.subscription = subscribe(
            this.messageContext,
            INTEREST_REGISTERED_CHANNEL,
            (message) => this.handleInterestRegistered(message),
            { scope: APPLICATION_SCOPE }
        );
    }

    unsubscribeFromInterestRegistered() {
        if (!this.subscription) {
            return;
        }

        unsubscribe(this.subscription);
        this.subscription = undefined;
    }

    handleInterestRegistered(message) {
        if (message?.serviceAppointmentId === this.recordId) {
            this.refreshInterestState();
        }
    }

    refreshInterestState = () => {
        if (!this.interestState) {
            return Promise.resolve(true);
        }

        if (this.refreshPromise) {
            return this.refreshPromise;
        }

        this.refreshPromise = refreshApex(this.interestState)
            .then(() => true)
            .catch((error) => {
                console.error('hot_serviceAppointmentInterestBanner refresh error', error);
                return false;
            })
            .finally(() => {
                this.refreshPromise = undefined;
            });

        return this.refreshPromise;
    };
}
