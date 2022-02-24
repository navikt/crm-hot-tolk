import { LightningElement, wire, api } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import STATUS from '@salesforce/schema/ServiceAppointment.Status';

export default class Hot_warningBannerServiceAppointment extends LightningElement {
    @api recordId;

    @wire(getRecord, { recordId: '$recordId', fields: [STATUS] })
    record;

    get isReleased() {
        return getFieldValue(this.record.data, STATUS) === 'Released to Freelance';
    }
}
