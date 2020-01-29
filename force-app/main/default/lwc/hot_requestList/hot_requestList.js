import { LightningElement, wire, track } from 'lwc';
import getRequestList from '@salesforce/apex/HOT_RequestListContoller.getRequestList';
console.log('RequestList:Start');
export default class RequestList extends LightningElement {
	@track columns = [{
		label: 'Record Id',
		fieldName: 'Id',
		type: 'id'
	},
	{
		label: 'Request Number',
		fieldName: 'Name',
		type: 'text'
	},
	{
		label: 'User name',
		fieldName: 'UserName__c',
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