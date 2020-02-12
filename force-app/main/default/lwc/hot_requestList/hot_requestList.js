import { LightningElement, wire, track } from 'lwc';
import getRequestList from '@salesforce/apex/HOT_RequestListContoller.getRequestList';
const actions = [
	{ label: 'Cancel Order', name: 'delete' },
	{ label: 'New Order', name: 'clone_order' },
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
				this.cancelOrder(row);
				break;
			case 'clone_order':
				this.cloneOrder(row);
				break;
			default:
		}
	}

	cancelOrder(row) {
		const { id } = row;
		const index = this.findRowIndexById(id);
		if (index !== -1) {
			if (this.data[index].status__c == "Canceled" || this.data[index].status__c == "Open") {
				this.data[index].status__c = "Canceled";
				//Signaling to User that they were successfull in canceling their Interpretation Order
				const evt = new ShowToastEvent({
					title: "Order was canceled",
					variant: "success"
				});
			}
			else {
				const evt = new ShowToastEvent({
					title: "Order cant be canceled",
					variant: "error"
				})
			}
			this.dispatchEvent(evt);
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
	cloneOrder(row) {
		const { id } = row;
		const index = this.findRowIndexById(id);
		if (index !== -1) {

			const evt = new ShowToastEvent({
				title: "Cloning Order",
				variant: "success"
			});
			this.dispatchEvent(evt);
		}
	}

}