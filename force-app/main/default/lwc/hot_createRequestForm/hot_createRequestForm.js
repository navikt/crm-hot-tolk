import { LightningElement, wire, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getPersonDetails from '@salesforce/apex/UserInfoDetails.getPersonDetails';

export default class RecordFormCreateExample extends LightningElement {

	@api clone;

	@track error;
	@track person;
	@track startTime;
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

	handleSuccess(event) {
		const evt = new ShowToastEvent({
			title: "Request created",
			variant: "success"
		});
		//window.scrollTo(0, 0);
		this.dispatchEvent(evt);
	}
	handleSubmit(event) {
		event.preventDefault(); // stop the form from submitting
		const fields = event.detail.fields;
		console.log(JSON.stringify(fields));

		fields.UserName__c = this.person.Name;
		fields.PersonalNumber__c = this.person.INT_Ident__c;
		fields.UserPhone__c = this.person.INT_Phone__c;
		fields.UserEmail__c = this.person.INT_Email__c;
		this.template.querySelector('lightning-record-edit-form').submit(fields);
	}

	//Tracking checkbox-value. If false --> Show user meeting location input
	@track sameLocation = true;

	toggled(event) {
		// Query the DOM
		const checked = Array.from(this.template.querySelectorAll('lightning-input'))
			//filters
			.filter(element => element.checked).map(element => element.label);
		console.log(checked);
		this.sameLocation = event.target.checked;
	}
}

