import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import REQUEST_OBJECT from '@salesforce/schema/HOT_Request__c'
import REQUEST_ID from '@salesforce/schema/HOT_Request__c.Name';
import USER_NAME from '@salesforce/schema/HOT_Request__c.UserName__c';
import PERSONAL_NUMBER from '@salesforce/schema/HOT_Request__c.PersonalNumber__c';
import USER_EMAIL from '@salesforce/schema/HOT_Request__c.UserEmail__c';
import USER_PHONE from '@salesforce/schema/HOT_Request__c.UserPhone__c';
import ASSIGNMENT_INFORMATION from '@salesforce/schema/HOT_Request__c.AssigmentInformation__c';
import START_TIME from '@salesforce/schema/HOT_Request__c.StartTime__c';
import END_TIME from '@salesforce/schema/HOT_Request__c.EndTime__c';
import MEETING_LOCATION from '@salesforce/schema/HOT_Request__c.MeetingLocation__c';
import INTERPRETATION_LOCATION from '@salesforce/schema/HOT_Request__c.InterpretationLocation__c';
import ADDITIONAL_INFORMATION from '@salesforce/schema/HOT_Request__c.AdditionalInformation__c';

export default class RecordFormCreateExample extends LightningElement {
	// objectApiName is "Account" when this component is placed on an account record page
	fields = [REQUEST_ID, USER_NAME, PERSONAL_NUMBER, USER_EMAIL, USER_PHONE, ASSIGNMENT_INFORMATION, START_TIME, END_TIME, MEETING_LOCATION, INTERPRETATION_LOCATION, ADDITIONAL_INFORMATION];

	handleSuccess(event) {
		const evt = new ShowToastEvent({
			title: "Request created",
			variant: "success"
		});
		this.dispatchEvent(evt);
	}
}