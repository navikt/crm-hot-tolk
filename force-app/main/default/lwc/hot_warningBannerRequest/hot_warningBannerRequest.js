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
        this.record = result;
        if (result.data) {
            this.getDuplicates();
        }
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

    @track duplicateRecords = [];
    @track hasDuplicates = false;
    async getDuplicates() {
        let requestId = this.recordId;
        let accountId = getFieldValue(this.record.data, ACCOUNT_ID);
        let result = await getOverlappingRecordsFromRequestId({ accountId, requestId });
        for (let record of result) {
            record.Link = '/' + record.Id;
            this.duplicateRecords.push(record);
        }
        this.hasDuplicates = this.duplicateRecords.length > 0;
    }
}
