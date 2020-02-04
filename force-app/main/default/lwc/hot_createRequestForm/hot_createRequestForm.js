import { LightningElement, wire, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getUserDetails from '@salesforce/apex/UserInfoDetails.getUserDetails';
import Id from '@salesforce/user/Id';

export default class RecordFormCreateExample extends LightningElement {

	userId = Id;
	@track error;
	@track user;
	@wire(getUserDetails, {
		recId: '$userId'
	})
	wiredUser({
		error,
		data
	}) {
		if (data) {
			this.user = data;
		} else if (error) {
			this.error = error;
		}
	}

	handleSuccess(event) {
		const evt = new ShowToastEvent({
			title: "Request created",
			variant: "success"
		});
		this.dispatchEvent(evt);
	}
	handleSubmit(event) {
		event.preventDefault(); // stop the form from submitting
		const fields = event.detail.fields;
		console.log(JSON.stringify(fields));

		fields.UserName__c = "vegard";
		fields.UserPhone__c = "12345678";
		fields.PersonalNumber__c = "01019512345";
		fields.UserEmail__c = "vegard@test.no"//user.Email;
		this.template.querySelector('lightning-record-edit-form').submit(fields);
	}


}