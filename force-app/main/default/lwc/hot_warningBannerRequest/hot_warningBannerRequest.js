import { LightningElement, wire, api, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import securityMeasures from '@salesforce/schema/HOT_Request__c.Account__r.CRM_Person__r.INT_SecurityMeasures__c';
import reservations from '@salesforce/schema/HOT_Request__c.Account__r.CRM_Person__r.HOT_Reservations__c';
import ACCOUNT_ID from '@salesforce/schema/HOT_Request__c.Account__c';
import getOverlappingRecordsFromRequestId from '@salesforce/apex/HOT_DuplicateHandler.getOverlappingRecordsFromRequestId';

export default class Hot_warningBannerRequest extends LightningElement {
    @api recordId;
    @track record;

    @wire(getRecord, {
        recordId: '$recordId',
        fields: [securityMeasures, reservations, ACCOUNT_ID]
    })
    wiredGetRecord(result) {
        console.log('wiredGetRecord');
        this.record = result;
        if (result.data) {
            console.log('true');
            this.getDuplicates();
        }
        console.log('done');
    }

    get securityMeasures() {
        return getFieldValue(this.record.data, securityMeasures).replace(/;/g, ', ');
    }

    get hasSecurityMeasures() {
        return (
            getFieldValue(this.record.data, securityMeasures) != null &&
            getFieldValue(this.record.data, securityMeasures) != '[]'
        );
    }

    get reservations() {
        return getFieldValue(this.record.data, reservations);
    }

    get hasReservations() {
        return getFieldValue(this.record.data, reservations) != null;
    }

    @track duplicateRequests = [];
    @track hasDuplicates = false;
    async getDuplicates() {
        console.log('getFieldValue(this.record.data, ACCOUNT_ID): ' + getFieldValue(this.record.data, ACCOUNT_ID));
        console.log('this.recordId: ' + this.recordId);
        let requestId = this.recordId;
        let accountId = getFieldValue(this.record.data, ACCOUNT_ID);
        let result = await getOverlappingRecordsFromRequestId({ accountId, requestId });
        console.log(result);
        console.log(JSON.stringify(result));
        this.duplicateRequests = result;
        this.hasDuplicates = this.duplicateRequests.length > 0;
        console.log(JSON.stringify(this.duplicateRequests));
        console.log(this.hasDuplicates);
    }
}
