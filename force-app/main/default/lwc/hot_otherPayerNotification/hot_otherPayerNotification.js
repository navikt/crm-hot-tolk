import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import USER_ID from '@salesforce/user/Id';

const FIELDS = ['HOT_Request__c.Company__c', 'HOT_Request__c.IsOtherEconomicProvicer__c', 'HOT_Request__c.CreatedDate'];

export default class Hot_otherPayerNotification extends LightningElement {
    @api recordId;
    @api objectApiName;

    _initialized = false;
    _prevCompany = null;
    _prevOtherPayerChecked = null;
    _prevConditionMet = false;

    get dismissedKey() {
        return `otherPayerToastDismissed_${this.recordId}_${USER_ID}`;
    }

    isDismissedOnLoad() {
        try {
            return window.localStorage.getItem(this.dismissedKey) === '1';
        } catch (e) {
            return false;
        }
    }

    markDismissedOnLoad() {
        try {
            window.localStorage.setItem(this.dismissedKey, '1');
        } catch (e) {}
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

        if (!this._initialized) {
            this._initialized = true;

            if (conditionNow) {
                let shouldShowOnFirstLoad = false;

                if (createdDate) {
                    const now = new Date();
                    const created = new Date(createdDate);
                    const timeDiffSeconds = (now - created) / 1000;

                    const justCreated = timeDiffSeconds < 5;

                    if (justCreated || !this.isDismissedOnLoad()) {
                        shouldShowOnFirstLoad = true;
                    }
                } else {
                    if (!this.isDismissedOnLoad()) {
                        shouldShowOnFirstLoad = true;
                    }
                }

                if (shouldShowOnFirstLoad) {
                    this.showToast({ fromLoad: true });
                }
            }

            this._prevCompany = company;
            this._prevOtherPayerChecked = otherPayerChecked;
            this._prevConditionMet = conditionNow;

            return;
        }

        const companyChanged = this._prevCompany !== company;
        const otherChanged = this._prevOtherPayerChecked !== otherPayerChecked;

        const conditionBecameTrue = !this._prevConditionMet && conditionNow;

        if ((companyChanged || otherChanged) && conditionBecameTrue) {
            this.showToast({ fromLoad: false });
        }

        this._prevCompany = company;
        this._prevOtherPayerChecked = otherPayerChecked;
        this._prevConditionMet = conditionNow;
    }

    showToast({ fromLoad = false } = {}) {
        const event = new ShowToastEvent({
            title: 'Annen betaler',
            message:
                'Virksomhet er fylt ut, men Annen betaler er ikke huket av. Vennligst vurder hvem som skal betale.',
            variant: 'warning',
            mode: 'sticky'
        });
        this.dispatchEvent(event);

        if (fromLoad) {
            this.markDismissedOnLoad();
        }
    }
}
