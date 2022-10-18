import { LightningElement, wire, api, track } from 'lwc';
//import { getRecord } from 'lightning/uiRecordApi';
import isDeceased from '@salesforce/apex/HOT_RequestController.isUserDeaceased';

export default class Hot_isDeceasedBannerRequest extends LightningElement {
    @track isDeceased;
    @api recordId;

    @wire(isDeceased)
    wiredIsDeceased(result) {
        if (result.data) {
            this.isDeceased = data;
        }
    }
}
