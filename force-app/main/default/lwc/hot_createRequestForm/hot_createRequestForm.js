import { LightningElement, wire, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getPersonDetails from '@salesforce/apex/UserInfoDetails.getPersonDetails';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import ACCOUNT_ID from '@salesforce/schema/User.AccountId';


export default class RecordFormCreateExample extends NavigationMixin(LightningElement) {

	@track reRender = 0;

	@track sameLocation = true;
	@track submitted = false;

	/*
		@wire(getRecord, {
			recordId: USER_ID,
			fields: [ACCOUNT_ID]
		}) UserId
		AccountId = UserId.AccountId;
	*/

	@track error;
	@track person;
	@track startTime;
	@track fieldValues = { Name: "", Subject__c: "", StartTime__c: "", EndTime__c: "", MeetingStreet__c: "", MeetingPostalCity__c: "", MeetingPostalCode__c: "", Description__C: "" };
	@wire(getPersonDetails)
	wiredPerson({
		error,
		data
	}) {
		if (data) {
			this.person = data;
		} else if (error) {
			this.error = error;
		}
	}
	handleChange(event) {
		this.startTime = event.detail.value;
	}

	handleSubmit(event) {

		event.preventDefault(); // stop the form from submitting

		//Handle submit-old
		const fields = event.detail.fields;
		console.log(JSON.stringify(fields));

		//console.log(AccountId);
		//fields.Account__c = this.AccountId;
		if (true) {
			fields.InterpretationStreet__c = fields.MeetingStreet__c;
			fields.InterpretationPostalCode__c = fields.MeetingPostalCode__c;
			fields.InterpretationPostalCity__c = fields.MeetingPostalCity__c;
		}

		this.template.querySelector('lightning-record-edit-form').submit(fields);
		this.goToMyRequests();
	}

	handleSuccess(event) {
		//HandleSuccess old
		const evt = new ShowToastEvent({
			title: "Request created",
			variant: "success"
		});
		//window.scrollTo(0, 0);
		this.dispatchEvent(evt);
		//this.submitted = true;

	}

	toggled(event) {
		// Query the DOM
		const checked = Array.from(this.template.querySelectorAll('lightning-input'))
			//filters
			.filter(element => element.checked).map(element => element.label);
		this.sameLocation = event.target.checked;
	}

	handleBack(event) {
		this.submitted = false;
	}

	connectedCallback() {
		let testURL = window.location.href;
		let newURL = new URL(testURL).searchParams;
		if (JSON.parse(newURL.get("fieldValues")) != null) {
			this.fieldValues = JSON.parse(newURL.get("fieldValues"));
			this.sameLocation = this.fieldValues.MeetingStreet__c == this.fieldValues.InterpretationStreet__c;

		}
	}

	//Navigation functions
	goToMyRequests() {
		this[NavigationMixin.Navigate]({
			type: 'comm__namedPage',
			attributes: {
				pageName: 'mine-bestillinger'
			}
		});
	}
	goHome() {
		this[NavigationMixin.Navigate]({
			type: 'comm__namedPage',
			attributes: {
				pageName: 'hjem'
			}
		});
	}
}