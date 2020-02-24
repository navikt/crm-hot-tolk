import { LightningElement, wire, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getPersonDetails from '@salesforce/apex/UserInfoDetails.getPersonDetails';
import { NavigationMixin } from 'lightning/navigation';

export default class RecordFormCreateExample extends NavigationMixin(LightningElement) {

	@track reRender = false;

	@track sameLocation = true;
	@track submitted = false;
	//comment
	@track error;
	@track person;
	@track startTime;
	@track fieldValues = { Name: "", Subject__c: "", StartTime__c: "", EndTime__c: "", MeetingAddress__c: "", MeetingPostalCity__c: "", MeetingPostalCode__c: "", Description__C: "" };
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

	connectedCallback() {
		let testURL = window.location.href;
		let newURL = new URL(testURL).searchParams;
		if (JSON.parse(newURL.get("fieldValues")) != null) {
			this.fieldValues = JSON.parse(newURL.get("fieldValues"));
			console.log("Field Values: " + newURL.get("fieldValues"));
			console.log("fieldValues.Name: " + JSON.stringify(this.fieldValues.Name));
			this.reRender = true;

		}

	}

	goToMyRequests() {
		this[NavigationMixin.Navigate]({
			type: 'comm__namedPage',
			attributes: {
				pageName: 'mine-bestillinger'
			}
		});
	}
}

