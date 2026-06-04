import { LightningElement, api, track, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';

import NAV_ICONS from '@salesforce/resourceUrl/HOT_tindIcons';

import getAccountPersonDetails from '@salesforce/apex/HOT_HighlightPanelController.getAccountPersonDetails';
import getRequest from '@salesforce/apex/HOT_HighlightPanelController.getRequestDetails';
import hasAccess from '@salesforce/apex/HOT_TindAccessErrorController.hasAccess';

const CONFIDENTIAL_LABELS = {
    FORTROLIG: 'Skjermet adresse - fortrolig',
    STRENGT_FORTROLIG: 'Skjermet adresse - strengt fortrolig',
    STRENGT_FORTROLIG_UTLAND: 'Skjermet adresse - strengt fortrolig'
};

export default class hot_tindRequestHighlightPanel extends LightningElement {
    @api recordId;
    @api objectApiName;

    requestData;
    wiredRequestResult;

    errorMessageList = {};
    errorMessages;
    uuAlertText = '';

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
            console.log('Request details:', this.requestData);
        } else if (error) {
            this.loadingStates.getRequest = false;
            console.error('getRequestDetails error:', error);
        }
    }

    addErrorMessage(errorName, error) {
        if (Array.isArray(error)) {
            this.errorMessageList[errorName] = error.flat();
        } else if (typeof error === 'object') {
            this.errorMessageList[errorName] = error.body?.exceptionType + ': ' + error.body?.message;
        } else {
            this.errorMessageList[errorName] = error;
        }
        this.updateErrorMessages();
    }

    closeErrorMessage(event) {
        const errorName = event.currentTarget.dataset.errorName;
        this.closeErrorMessages(errorName);
    }

    closeErrorMessages(errorName) {
        if (Object.keys(this.errorMessageList).includes(errorName)) {
            delete this.errorMessageList[errorName];
            this.updateErrorMessages();
        }
    }

    updateErrorMessages() {
        this.errorMessages = Object.keys(this.errorMessageList).map((errorName) => {
            return { errorName: errorName, error: this.errorMessageList[errorName] };
        });
    }

    get isLoading() {
        return Object.keys(this.loadingStates).some((key) => this.loadingStates[key]);
    }

    get warningIconSrc() {
        return NAV_ICONS + '/warningTriangle.svg#warningTriangle';
    }

    get xMarkIconSrc() {
        return NAV_ICONS + '/xMarkIcon.svg#xMarkIcon';
    }

    handleRefreshRequest() {
        // Refresh the wired data when the event is received from child component
        if (this.wiredRequestResult) {
            refreshApex(this.wiredRequestResult);
        }
    }
}
