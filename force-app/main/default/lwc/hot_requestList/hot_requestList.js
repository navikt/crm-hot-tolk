import { LightningElement, wire, track, api } from 'lwc';
import getRequestList from '@salesforce/apex/HOT_RequestListContoller.getRequestList';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { updateRecord } from 'lightning/uiRecordApi';
import STATUS from '@salesforce/schema/HOT_Request__c.Status__c';
import REQUEST_ID from '@salesforce/schema/HOT_Request__c.Id';

var actions = [
	{ label: 'Cancel Order', name: 'delete' },
	{ label: 'Copy Order', name: 'clone_order' },
];
export default class RequestList extends LightningElement {

	@track columns = [
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
			label: 'Meeting Address',
			fieldName: 'MeetingAddress__C',
			type: 'text'
		},
		{
			label: 'Assignment Information',
			fieldName: 'AssigmentInformation__c',
			type: 'text'
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
		console.log(JSON.stringify(row));

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

	findRowIndexById(Id) {
		let ret = -1;
		this.requests.some((row, index) => {
			if (row.Id === Id) {
				ret = index;
				return true;
			}
			return false;
		});
		return ret;
	}

	cancelOrder(row) {
		const { Id } = row;
		const index = this.findRowIndexById(Id);
		if (index != -1) {
			if (this.requests[index].Status__c == "Open") {
				//cancelAppointment(Id);
				const fields = {};
				fields[REQUEST_ID.fieldApiName] = Id;
				fields[STATUS.fieldApiName] = "Canceled";
				const recordInput = { fields };
				updateRecord(recordInput)
					.then(() => {
						this.dispatchEvent(
							new ShowToastEvent({
								title: 'Success',
								message: 'Contact updated',
								variant: 'success'
							})
						);
						// Display fresh data in the form
						return refreshApex(this.contact);
					})
					.catch(error => {
						this.dispatchEvent(
							new ShowToastEvent({
								title: 'Error creating record',
								message: error.body.message,
								variant: 'error'
							})
						);
					});
			}
			const evt = new ShowToastEvent({
				title: "Order was canceled",
				variant: "success"
			});
			//this.dispatchEvent(evt);
		}
		else {
			const evt = new ShowToastEvent({
				title: "Order can not be canceled",
				variant: "error"
			});
			//this.dispatchEvent(evt);
		}
	}

	cloneOrder(row) {
		const { Id } = row;
		const index = this.findRowIndexById(Id);
		console.log(index);
		console.log(JSON.stringify(row));

		if (index != -1) {
			//clone = this.requests[index];
			const evt = new ShowToastEvent({
				title: "Cloning Order",
				variant: "success"
			});
			this.dispatchEvent(evt);
		}
	}

}