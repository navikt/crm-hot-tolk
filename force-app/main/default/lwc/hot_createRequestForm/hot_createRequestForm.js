import { LightningElement, wire, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getPersonDetails from '@salesforce/apex/UserInfoDetails.getPersonDetails';
import { NavigationMixin } from 'lightning/navigation';
import { CurrentPageReference } from 'lightning/navigation';

export default class RecordFormCreateExample extends NavigationMixin(LightningElement) {

	@wire(CurrentPageReference)
	pageRef;

	@track sameLocation = true;
	@track submitted = false;
	//comment
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
		this.goToMyRequests();
		//this.submitted = true;
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
		console.log('Submitted');
	}

	handleAbort(event) {
		const evt = new ShowToastEvent({
			title: "Form was aborted",
			variant: "warning"
		});
		window.scrollTo(0, 0);
		this.dispatchEvent(evt);
	}


	toggled(event) {
		// Query the DOM
		const checked = Array.from(this.template.querySelectorAll('lightning-input'))
			//filters
			.filter(element => element.checked).map(element => element.label);
		console.log(checked);
		this.sameLocation = event.target.checked;
	}

	handleBack(event) {
		this.submitted = false;
	}

	goToMyRequests() {
		console.log('going to my requests');
		this[NavigationMixin.Navigate]({
			type: 'standard__navItemPage',
			attributes: {
				apiName: 'MyRequests__c'
			}
		});
		console.log('Should have navigated');
	}
	navigateToWebPage() {
		// Navigate to a URL
		this[NavigationMixin.Navigate]({
			type: 'standard__webPage',
			attributes: {
				url: 'http://salesforce.com'
			}
		},
			true // Replaces the current page in your browser history with the URL
		);
	}
}

