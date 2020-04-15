import { LightningElement, wire, api, track } from "lwc";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import securityMeasures from '@salesforce/schema/HOT_Request__c.Account__r.CRM_Person__r.INT_SecurityMeasures__c';
import reservations from '@salesforce/schema/HOT_Request__c.Account__r.CRM_Person__r.HOT_Reservations__c';
import START_TIME from '@salesforce/schema/HOT_Request__c.StartTime__c';
import END_TIME from '@salesforce/schema/HOT_Request__c.EndTime__c';
import getRequestList from '@salesforce/apex/HOT_RequestListContoller.getRequestList';

export default class Hot_warningBannerRequest extends LightningElement {
	@api recordId;

	@wire(getRecord, { recordId: "$recordId", fields: [securityMeasures, reservations, START_TIME, END_TIME] })
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

	@wire(getRequestList)
	wiredRequest(result) {
		this.wiredRequestsResult = result;
		if (result.data) {
			this.allRequests = result.data;
			this.filterRequests();
			this.error = undefined;
		} else if (result.error) {
			this.error = result.error;
			this.requests = undefined;
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
	duplicateRequests = [];
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

			if (JSON.stringify(duplicates) != "[]") {
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
				this.template.querySelector(".duplicate-links").innerHTML = htmlLinks;


			}
		}
		return duplicates;
	}
	get duplicates() {
		var duplicates = this.isDuplicate();
		return duplicates;
	}
	get getHasDuplicates() {
		return this.duplicateRequests != [] && this.isActive;
	}

}