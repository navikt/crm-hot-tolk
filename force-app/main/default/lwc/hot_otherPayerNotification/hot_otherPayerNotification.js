import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';

const FIELDS = ['HOT_Request__c.Company__c', 'HOT_Request__c.IsOtherEconomicProvicer__c', 'HOT_Request__c.CreatedDate'];

export default class Hot_otherPayerNotification extends LightningElement {
    @api recordId;
    @api objectApiName;

    showBanner = false;

    _initialized = false;
    _prevConditionMet = false;

    get dismissedKey() {
        return `otherPayerBannerDismissed_${this.recordId}_${USER_ID}`;
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

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ data, error }) {
        if (error) {
            console.error('hot_otherPayerNotification getRecord error', error);
            return;
        }
        if (!data) return;

        const company = data.fields.Company__c?.value || null;
        const otherPayerChecked = data.fields.IsOtherEconomicProvicer__c?.value === true;
        const createdDate = data.fields.CreatedDate?.value;

        const conditionNow = !!company && !otherPayerChecked;

        // If condition is no longer true, hide banner and allow it to show again next time
        if (!conditionNow) {
            this.showBanner = false;
            this.clearDismissed();
        }

        if (!this._initialized) {
            this._initialized = true;
            this._prevConditionMet = conditionNow;

            let shouldShowOnFirstLoad = false;
            if (conditionNow) {
                if (createdDate) {
                    const now = new Date();
                    const created = new Date(createdDate);
                    const justCreated = (now - created) / 1000 < 5;

                    // show if just created OR not dismissed
                    shouldShowOnFirstLoad = justCreated || !this.isDismissed();
                } else {
                    shouldShowOnFirstLoad = !this.isDismissed();
                }
            }

            if (shouldShowOnFirstLoad) {
                this.showBanner = true;
            }

            return;
        }

        // Show when condition becomes true again (unless previously dismissed)
        const conditionBecameTrue = !this._prevConditionMet && conditionNow;
        if (conditionBecameTrue && !this.isDismissed()) {
            this.showBanner = true;
        }

        this._prevConditionMet = conditionNow;
    }
}
