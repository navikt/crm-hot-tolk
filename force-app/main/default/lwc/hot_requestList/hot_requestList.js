import { LightningElement, wire, track } from 'lwc';
import getRequestList from '@salesforce/apex/HOT_RequestListContoller.getRequestList';
console.log('RequestList:Start');
export default class RequestList extends LightningElement {
	@track columns = [{
		label: 'Request Id',
		fieldName: 'Name',
		type: 'id'
	},
	{
		label: 'User Name',
		fieldName: 'UserName__c',
		type: 'text'
	},
	{
		label: 'Assignment Information',
		fieldName: 'AssigmentInformation__c',
		type: 'text'
	},
	{
		label: 'Start Time',
		fieldName: 'StartTime__c',
		type: 'date',
		typeAttributes: {
			day: 'numeric',
			month: 'numeric',
			year: 'numeric',
			hour: '2-digit',
			minute: '2-digit',
			hour12: false
		},
	},
	{
		label: 'End Time',
		fieldName: 'EndTime__c',
		type: 'date',
		typeAttributes: {
			day: 'numeric',
			month: 'numeric',
			year: 'numeric',
			hour: '2-digit',
			minute: '2-digit',
			hour12: false
		},
	},
	{
		label: 'Status',
		fieldName: 'Status__c',
		type: 'text'
	}

	];

	@track requests;
	@track error;
	wiredRequestsResult;
	@wire(getRequestList)
	wiredRequest(result) {
		console.log('RequestList:result: ' + result);
		this.wiredRequestsResult = result;
		if (result.data) {
			this.requests = result.data;
			this.error = undefined;
		} else if (result.error) {
			this.error = result.error;
			this.requests = undefined;
		}
	}
}