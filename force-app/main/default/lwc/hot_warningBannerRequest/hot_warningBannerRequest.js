import { LightningElement, wire, api } from "lwc";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import securityMeasures from '@salesforce/schema/HOT_Request__c.Account__r.CRM_Person__r.INT_SecurityMeasures__c';
import reservations from '@salesforce/schema/HOT_Request__c.Account__r.CRM_Person__r.HOT_Reservations__c';

export default class Hot_warningBannerRequest extends LightningElement {
	@api recordId;

	@wire(getRecord, { recordId: "$recordId", fields: [securityMeasures, reservations] })
	record;

	get securityMeasures() {
		return getFieldValue(this.record.data, securityMeasures).replace(/;/g, ", ");
	}

	get hasSecurityMeasures() {
		return getFieldValue(this.record.data, securityMeasures) != null;
	}

	get reservations() {
		return getFieldValue(this.record.data, reservations);
	}

	get hasReservations() {
		return getFieldValue(this.record.data, reservations) != null;
	}
}