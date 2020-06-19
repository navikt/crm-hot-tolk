import { LightningElement, wire, api, track } from "lwc";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import IS_RELEASED from '@salesforce/schema/ServiceAppointment.HOT_IsReleasedToFreelance__c';

export default class Hot_warningBannerServiceAppointment extends LightningElement {
	@api recordId;

	@wire(getRecord, { recordId: "$recordId", fields: [IS_RELEASED] })
	record;

	get isReleased() {
		return getFieldValue(this.record.data, IS_RELEASED);
	}
}