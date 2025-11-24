import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const FIELDS = ['HOT_Request__c.Company__c', 'HOT_Request__c.IsOtherEconomicProvicer__c', 'HOT_Request__c.CreatedDate'];

export default class Hot_otherPayerNotification extends LightningElement {
    @api recordId;
    @api objectApiName;

    _initialized = false;
    _prevCompany = null;
    _prevOtherPayerChecked = null;
    _prevConditionMet = false;

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

            if (createdDate && conditionNow) {
                const now = new Date();
                const created = new Date(createdDate);
                const timeDiffSeconds = (now - created) / 1000;

                if (timeDiffSeconds < 5) {
                    this.showToast();
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
            this.showToast();
        }

        this._prevCompany = company;
        this._prevOtherPayerChecked = otherPayerChecked;
        this._prevConditionMet = conditionNow;
    }

    showToast() {
        const event = new ShowToastEvent({
            title: 'Annen betaler',
            message:
                'Virksomhet er fylt ut, men Annen betaler er ikke huket av. Vennligst vurder hvem som skal betale.',
            variant: 'warning',
            mode: 'sticky'
        });
        this.dispatchEvent(event);
    }
}
