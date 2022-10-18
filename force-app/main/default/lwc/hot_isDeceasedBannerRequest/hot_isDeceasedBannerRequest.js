import { LightningElement, wire, api, track } from 'lwc';
//import { getRecord } from 'lightning/uiRecordApi';
import isDeceased from '@salesforce/apex/HOT_RequestController.isUserDeaceased';

export default class Hot_isDeceasedBannerRequest extends LightningElement {
    @track isDeceased;
    @api recordId;

    connectedCallback() {
        isDeceased({
            requestId: this.recordId
        }).then((data) => {
            this.isDeceased = data;
        });
    }
}
