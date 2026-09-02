import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';

const SERVICE_APPOINTMENT_FIELDS = ['ServiceAppointment.HOT_Request__c'];
const REQUEST_FIELDS = ['HOT_Request__c.MessageToDispatcher__c'];

export default class Hot_dispatcherMessageNotification extends LightningElement {
    @api recordId;
    @api objectApiName;

    showBanner = false;
    messageToDispatcher = '';
    requestId;

    get dismissedKey() {
        const keyRecordId = this.requestId || this.recordId;
        return `dispatcherMessageBannerDismissed_${keyRecordId}_${USER_ID}`;
    }

    isDismissed() {
        try {
            return window.localStorage.getItem(this.dismissedKey) === '1';
        } catch (e) {
            return false;
        }
    }

    markDismissed() {
        try {
            window.localStorage.setItem(this.dismissedKey, '1');
        } catch (e) {}
    }

    clearDismissed() {
        try {
            window.localStorage.removeItem(this.dismissedKey);
        } catch (e) {}
    }

    handleClose() {
        this.showBanner = false;
        this.markDismissed();
    }

    // When user navigates away, component is destroyed -> banner is gone.
    disconnectedCallback() {
        this.showBanner = false;
    }

    @wire(getRecord, { recordId: '$recordId', fields: SERVICE_APPOINTMENT_FIELDS })
    wiredServiceAppointment({ data, error }) {
        if (error) {
            console.error('hot_dispatcherMessageNotification service appointment getRecord error', error);
            return;
        }
        if (!data) return;

        this.requestId = data.fields.HOT_Request__c?.value || null;
    }

    @wire(getRecord, { recordId: '$requestId', fields: REQUEST_FIELDS })
    wiredRequest({ data, error }) {
        if (!this.requestId) {
            this.messageToDispatcher = '';
            this.showBanner = false;
            this.clearDismissed();
            return;
        }

        if (error) {
            console.error('hot_dispatcherMessageNotification request getRecord error', error);
            return;
        }
        if (!data) return;

        const message = data.fields.MessageToDispatcher__c?.value?.trim() || '';
        const hasMessage = message.length > 0;

        this.messageToDispatcher = message;

        if (!hasMessage) {
            this.showBanner = false;
            this.clearDismissed();
            return;
        }

        this.showBanner = !this.isDismissed();
    }
}
