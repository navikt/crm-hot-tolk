import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const FIELDS = [
    'HOT_Request__c.Company__c',
    'HOT_Request__c.IsOtherEconomicProvicer__c',
    'HOT_Request__c.LastModifiedDate'
];

export default class Hot_otherPayerNotification extends LightningElement {
    @api recordId;
    @api objectApiName;

    _lastSeenModified = null;
    _initialized = false;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ data, error }) {
        if (error) {
            console.error('hot_otherPayerNotification getRecord error', error);
            return;
        }
        if (!data) return;

        const company = data.fields.Company__c?.value;
        const otherPayerChecked = data.fields.IsOtherEconomicProvicer__c?.value === true;
        const modified = data.fields.LastModifiedDate?.value;

        if (!this._initialized) {
            this._initialized = true;
            this._lastSeenModified = modified;
            return;
        }

        if (this._lastSeenModified !== modified) {
            this._lastSeenModified = modified;

            if (company && !otherPayerChecked) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Annen Betaler',
                        message:
                            'Virksomhet er fylt ut, men Annen betaler ikke er huket av. Vennligst vurder hvem som skal betale.',
                        variant: 'warning',
                        mode: 'sticky'
                    })
                );
            }
        }
    }
}
