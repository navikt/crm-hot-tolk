import { LightningElement, wire, track } from 'lwc';
import getRequestList from '@salesforce/apex/HOT_RequestListContoller.getRequestList';
const actions = [
	{ label: 'Show details', name: 'show_details' },
	{ label: 'Delete', name: 'delete' },
];
console.log('RequestList:Start');
export default class RequestList extends LightningElement {

	@track columns = [{
		label: 'Request Id',
		fieldName: 'Name',
		type: 'id'
	},
	{
		label: 'Assignment Information',
		fieldName: 'AssigmentInformation__c',
		type: 'text'
	},
	{
		label: 'Interpretation Address',
		fieldName: 'InterpretationAddress__C',
		type: 'text'
	},
	{
		label: 'Meeting Address',
		fieldName: 'MeetingAddress__C',
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
		}
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
		}
	},
	{
		label: 'Status',
		fieldName: 'Status__c',
		type: 'text'
	},
	{
		type: 'action',
		typeAttributes: { rowActions: actions },
	},
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

	//Handle Row Action
	handleRowAction(event) {
		const actionName = event.detail.action.name;
		const row = event.detail.row;
		switch (actionName) {
			case 'delete':
				this.deleteRow(row);
				break;
			case 'show_details':
				this.showRowDetails(row);
				break;
			default:
		}
	}

	deleteRow(row) {
		const { id } = row;
		const index = this.findRowIndexById(id);
		if (index !== -1) {
			this.data = this.data
				.slice(0, index)
				.concat(this.data.slice(index + 1));
		}
	}

	findRowIndexById(id) {
		let ret = -1;
		this.data.some((row, index) => {
			if (row.id === id) {
				ret = index;
				return true;
			}
			return false;
		});
		return ret;
	}

}