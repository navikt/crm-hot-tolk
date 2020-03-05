import { LightningElement, wire, track, api } from 'lwc';
import getRequestList from '@salesforce/apex/HOT_RequestListContoller.getRequestList';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { updateRecord } from 'lightning/uiRecordApi';
import STATUS from '@salesforce/schema/HOT_Request__c.Status__c';
import REQUEST_ID from '@salesforce/schema/HOT_Request__c.Id';
import { refreshApex } from '@salesforce/apex';
import { NavigationMixin } from 'lightning/navigation';
import HOT_Request__c from '@salesforce/schema/WorkOrder.HOT_Request__c';


var actions = [
	{ label: 'Cancel Order', name: 'delete' },
	{ label: 'Copy Order', name: 'clone_order' },
];
export default class RequestList extends NavigationMixin(LightningElement) {

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
			fieldName: 'MeetingStreet__c',
			type: 'text'
		},
		{
			label: 'Subject',
			fieldName: 'Subject__c',
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

	@track rerender;
	@track requests;
	@track error;
	wiredRequestsResult;

	@wire(getRequestList)
	wiredRequest(result) {
		//console.log('RequestList length: ' + JSON.stringify(result.data.size()));
		this.wiredRequestsResult = result;
		if (result.data) {
			this.requests = result.data;
			this.error = undefined;
		} else if (result.error) {
			this.error = result.error;
			this.requests = undefined;
		}
		//console.log('RequestList:result: ' + JSON.stringify(this.requests));

	}


	//Handle Row Action
	handleRowAction(event) {
		const actionName = event.detail.action.name;
		const row = event.detail.row;
		//console.log(JSON.stringify(row));

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
				const fields = {};
				fields[REQUEST_ID.fieldApiName] = Id;
				fields[STATUS.fieldApiName] = "Canceled";
				const recordInput = { fields };
				updateRecord(recordInput)
					.then(() => {
						this.dispatchEvent(
							new ShowToastEvent({
								title: 'Success',
								message: 'Order was canceled',
								variant: 'success'
							})
						);
						// Display fresh data in the form
						//console.log('Trying to refresh');
						refreshApex(this.wiredRequestsResult);
					})
					.catch(error => {
						this.dispatchEvent(
							new ShowToastEvent({
								title: 'An error oocured canceling the appointment',
								message: error.body.message,
								variant: 'error'
							})
						);
					});
			}
			else {
				const evt = new ShowToastEvent({
					title: "Order can not be canceled",
					variant: "error"
				});
				this.dispatchEvent(evt);
			}
		}
	}

	cloneOrder(row) {
		const { Id } = row;
		const index = this.findRowIndexById(Id);
		if (index != -1) {
			//Here we should get the entire record from salesforce, to get entire meeting address.
			let clone = this.requests[index];
			//console.log(JSON.stringify(clone));
			this[NavigationMixin.Navigate]({
				type: 'comm__namedPage',
				attributes: {
					pageName: 'ny-bestilling'
				},
				state: {
					fieldValues: JSON.stringify(clone),
					fromList: true,
				}
			});
		}
	}

	goToNewRequest() {
		this[NavigationMixin.Navigate]({
			type: 'comm__namedPage',
			attributes: {
				pageName: 'ny-bestilling'
			},
			state: {
				fromList: true,
			}
		});
	}
	goHome() {
		this[NavigationMixin.Navigate]({
			type: 'comm__namedPage',
			attributes: {
				pageName: 'hjem'
			}
		});
	}

}