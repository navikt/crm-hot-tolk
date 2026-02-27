import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

const fieldMap = { WorkOrder: 'ServiceAppointment.HOT_WorkOrderLineItem__r.WorkOrder.Id' };
export default class Hot_messagingMessageComponentCustomObject extends LightningElement {
    @api customObjectApiName;
    @api recordId;
    fields;
    connectedCallback() {
        if (this.recordId && this.customObjectApiName) {
            this.fields = fieldMap[this.customObjectApiName];
        }
    }
    wiredRecord;
    @wire(getRecord, { recordId: '$recordId', fields: '$fields' })
    wiredRecord(value) {
        this.wiredRecord = value;
    }
    get isRecordLoaded() {
        return this.wiredRecord && this.wiredRecord.data;
    }
    get isError() {
        return this.wiredRecord && this.wiredRecord.error;
    }
    get errorMessage() {
        return this.isError ? this.wiredRecord.error.body.message : '';
    }
    get customRecordId() {
        return getFieldValue(this.wiredRecord.data, fieldMap[this.customObjectApiName]);
    }
}
