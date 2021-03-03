import { LightningElement, wire, api, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import ACCOUNT_ID from '@salesforce/schema/WorkOrder.AccountId';
import getOverlappingRecordsFromWorkOrderId from '@salesforce/apex/HOT_DuplicateHandler.getOverlappingRecordsFromWorkOrderId';

export default class Hot_warningBannerWorkOrder extends LightningElement {
    @api recordId;
    @track record;

    @wire(getRecord, {
        recordId: '$recordId',
        fields: [ACCOUNT_ID]
    })
    wiredGetRecord(result) {
        this.record = result;
        if (result.data) {
            this.getDuplicates();
        }
    }

    @track duplicateRecords = [];
    @track hasDuplicates = false;
    async getDuplicates() {
        let workOrderId = this.recordId;
        let accountId = getFieldValue(this.record.data, ACCOUNT_ID);
        let result = await getOverlappingRecordsFromWorkOrderId({ accountId, workOrderId });
        for (let record of result) {
            record.Link = '/' + record.Id;
            this.duplicateRecords.push(record);
        }
        this.hasDuplicates = this.duplicateRecords.length > 0;
    }
}
