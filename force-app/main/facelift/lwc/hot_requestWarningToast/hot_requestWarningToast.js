import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';

const FIELDS = [
    'Request__c.StartTime__c',
    'Request__c.CreatedDate',
    'Request__c.Source__c'
];

export default class Hot_requestWarningToast extends LightningElement {
    @api recordId;
    toastDisplayed = false;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (data && !this.toastDisplayed) {
            this.checkStartTime(data);
        } else if (error) {
            console.error('Error fetching record', error);
        }
    }

    checkStartTime(recordData) {
        const startTime = recordData.fields.StartTime__c.value;
        const createdDate = recordData.fields.CreatedDate.value;
        const now = new Date();

        const created = new Date(createdDate);
        const timeDiff = (now - created) / 1000;

        if (startTime < now.toISOString() && timeDiff < 10 && source === 'Community') {
            this.showToast();
            this.warningShown = true;
        }
    }

    showToast() {
        const event = new ShowToastEvent({
            title: 'Advarsel',
            message: 'Du har registrert en dato i fortiden. Kontroller at dette stemmer.',
            variant: 'warning',
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }
}