import { LightningElement, api, track, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';

import getRequest from '@salesforce/apex/HOT_HighlightPanelController.getRequestDetails';

export default class hot_tindRequestHighlightPanel extends LightningElement {
    @api recordId;
    @api objectApiName;

    requestData;
    wiredRequestResult;

    @track loadingStates = {
        getRequest: true
    };

    @wire(getRequest, { recordId: '$recordId' })
    wiredRequestDetails(result) {
        this.wiredRequestResult = result;
        const { error, data } = result;
        if (data) {
            this.requestData = data;
            this.loadingStates.getRequest = false;
        } else if (error) {
            this.loadingStates.getRequest = false;
            console.error('getRequestDetails error:', error);
        }
    }

    get isLoading() {
        return Object.keys(this.loadingStates).some((key) => this.loadingStates[key]);
    }

    handleRefreshRequest() {
        if (this.wiredRequestResult) {
            refreshApex(this.wiredRequestResult);
        }
    }
}
