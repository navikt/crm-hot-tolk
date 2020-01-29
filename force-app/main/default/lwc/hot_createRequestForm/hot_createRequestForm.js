import { LightningElement, track } from 'lwc';
import { createRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import REQUEST_OBJECT from '@salesforce/schema/HOT_Request__c';
import USER_NAME_FIELD from '@salesforce/schema/HOT_Request__c.UserName__c';

export default class CreateRequestRecord extends LightningElement {
	@track recordId;
	userName = '';

	handleUserNameChange(event) {
		this.recordId = undefined;
		this.userName = event.target.value;
	}
	createRequest() {
		const fields = {};
		fields[USER_NAME_FIELD.fieldApiName] = this.userName;
		const recordInput = { apiName: REQUEST_OBJECT.objectApiName, fields };
		createRecord(recordInput)
			.then(request => {
				this.recordId = request.id;
				this.dispatchEvent(
					new ShowToastEvent({
						title: 'Success',
						message: 'Request created',
						variant: 'success',
					}),
				);
			})
			.catch(error => {
				this.dispatchEvent(
					new ShowToastEvent({
						title: 'Error creating record',
						message: error.body.message,
						variant: 'error',
					}),
				);
			});
	}
}