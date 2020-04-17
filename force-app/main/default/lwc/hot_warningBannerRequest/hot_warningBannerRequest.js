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

	@track allRequests;
	@track requests;
	@track error;
	wiredRequestsResult;
	@api accountId;

	@wire(getRequestListFromAccountFromRequestId, { recordId: '$recordId' })
	wiredRequest(result) {
		this.wiredRequestsResult = result;
		if (result.data) {
			this.allRequests = result.data;
			this.filterRequests();
			this.error = undefined;
		} else if (result.error) {
			this.error = result.error;
			this.allRequests = undefined;
		}
	}
	isActive = false;
	filterRequests() {
		var tempRequests = [];
		for (var i = 0; i < this.allRequests.length; i++) {
			if (this.allRequests[i].ExternalRequestStatus__c != "Avlyst" &&
				this.allRequests[i].ExternalRequestStatus__c != "Dekket" &&
				this.allRequests[i].ExternalRequestStatus__c != "Udekket") {
				tempRequests.push(this.allRequests[i]);
				if (this.allRequests[i].Id == this.recordId) {
					this.isActive = true;
				}
			}
		}
		this.requests = tempRequests;
	}

	@track duplicateRequests = [];
	isDuplicate() {

		var duplicates = [];
		var duplicateIds = [];
		var duplicateLinks = []

		if (this.requests && this.isActive) {

			for (var i = 0; i < this.requests.length; i++) {
				if ((this.requests[i].StartTime__c <= getFieldValue(this.record.data, START_TIME) && getFieldValue(this.record.data, START_TIME) <= this.requests[i].EndTime__c
					||
					getFieldValue(this.record.data, START_TIME) <= this.requests[i].StartTime__c && this.requests[i].StartTime__c <= getFieldValue(this.record.data, END_TIME))
					&&
					this.requests[i].Id != this.recordId) {
					duplicates.push(this.requests[i].Name);
					duplicateIds.push(this.requests[i].Id);
					duplicateLinks.push("/lightning/r/HOT_Request__c/" + this.requests[i].Id + "/view");
				}
			}
			if (duplicates.length > 0) {
				this.duplicateRequests = duplicates;
				var htmlLinks = "";
				for (var i = 0; i < duplicates.length; i++) {
					if (i != duplicates.length - 1) {
						htmlLinks = htmlLinks + " <a href=\"" + duplicateLinks[i] + "\">" + duplicates[i] + "</a>,";
					}
					else {
						htmlLinks = htmlLinks + " <a href=\"" + duplicateLinks[i] + "\">" + duplicates[i] + "</a>";
					}
				}

				htmlLinks = "Brukeren har allerede tolkebestillinger i samme tidsrom:" + htmlLinks;
				var x = this.template.querySelector(".duplicate-links");
				if (x != null) {
					x.innerHTML = htmlLinks;
				}
			}
		}
		return duplicates;
	}
	get getHasDuplicates() {
		var duplicates = this.isDuplicate();
		return duplicates.length > 0 && this.isActive;
	}

}