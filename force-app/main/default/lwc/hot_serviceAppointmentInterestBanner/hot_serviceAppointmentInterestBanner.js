import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import hasRegisteredInterest from '@salesforce/apex/HOT_InterestedResourceBannerController.hasRegisteredInterest';
import { registerRefreshHandler, unregisterRefreshHandler } from 'lightning/refresh';

export default class Hot_serviceAppointmentInterestBanner extends LightningElement {
    @api recordId;

    refreshHandlerId;
    refreshPromise;

    @wire(hasRegisteredInterest, { serviceAppointmentId: '$recordId' })
    interestState;

    connectedCallback() {
        this.refreshHandlerId = registerRefreshHandler(this, this.refreshInterestState);

        document.addEventListener('visibilitychange', this.refreshWhenVisible);
        window.addEventListener('pageshow', this.refreshInterestState);
    }

    disconnectedCallback() {
        if (this.refreshHandlerId) {
            unregisterRefreshHandler(this.refreshHandlerId);
        }

        document.removeEventListener('visibilitychange', this.refreshWhenVisible);
        window.removeEventListener('pageshow', this.refreshInterestState);
    }

    get showBanner() {
        return this.interestState?.data === true;
    }

    refreshWhenVisible = () => {
        if (document.visibilityState === 'visible') {
            return this.refreshInterestState();
        }

        return Promise.resolve(true);
    };

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