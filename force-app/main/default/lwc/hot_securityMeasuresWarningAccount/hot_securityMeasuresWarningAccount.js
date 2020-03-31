import { LightningElement, wire, api } from "lwc";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import securityMeasures from '@salesforce/schema/Account.CRM_Person__r.INT_SecurityMeasures__c';

export default class Hot_securityMeasuresWarning extends LightningElement {
	@api recordId;

	@wire(getRecord, { recordId: "$recordId", fields: [securityMeasures] })
	record;

	get securityMeasures() {
		return getFieldValue(this.record.data, securityMeasures).replace(/;/g, ", ");
	}

	get hasSecurityMeasures() {
		return getFieldValue(this.record.data, securityMeasures) != null;
	}
}