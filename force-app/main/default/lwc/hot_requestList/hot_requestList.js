import { LightningElement, wire, track, api } from 'lwc';
import getRequestList from '@salesforce/apex/HOT_RequestListContoller.getRequestList';
import { updateRecord } from 'lightning/uiRecordApi';
import STATUS from '@salesforce/schema/HOT_Request__c.Status__c';
import REQUEST_ID from '@salesforce/schema/HOT_Request__c.Id';
import { refreshApex } from '@salesforce/apex';
import { NavigationMixin } from 'lightning/navigation';
import HOT_Request__c from '@salesforce/schema/WorkOrder.HOT_Request__c';


var actions = [
	{ label: 'Avlys', name: 'delete' },
	{ label: 'Kopier', name: 'clone_order' },
	{ label: 'Rediger', name: 'edit_order' },
];
export default class RequestList extends NavigationMixin(LightningElement) {

	@track columns = [
		{
			label: 'Start tid',
			fieldName: 'StartTime__c',
			type: 'date',
			sortable: true,
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
			label: 'Slutt tid',
			fieldName: 'EndTime__c',
			type: 'date',
			sortable: true,
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
			label: 'Oppmøtested',
			fieldName: 'MeetingStreet__c',
			type: 'text',
			sortable: true,
		},
		{
			label: 'Tema',
			fieldName: 'Subject__c',
			type: 'text',
			sortable: true,
		},
		{
			label: 'Status',
			fieldName: 'ExternalRequestStatus__c',
			type: 'text',
			sortable: true,
		},
		{
			type: 'action',
			typeAttributes: { rowActions: actions },
		},
	];


	@track rerender;
	@track requests;
	@track allRequests;
	@track error;
	wiredRequestsResult;

	@wire(getRequestList)
	wiredRequest(result) {
		this.wiredRequestsResult = result;
		if (result.data) {
			this.allRequests = result.data;
			this.filterRequests();
			this.showHideInactives();
			this.error = undefined;
		} else if (result.error) {
			this.error = result.error;
			this.allRequests = undefined;
		}

	}

	filterRequests() {
		var tempRequests = [];
		for (var i = 0; i < this.allRequests.length; i++) {
			if (this.allRequests[i].ExternalRequestStatus__c != "Avlyst" &&
				this.allRequests[i].ExternalRequestStatus__c != "Dekket" &&
				this.allRequests[i].ExternalRequestStatus__c != "Udekket") {
				tempRequests.push(this.allRequests[i]);
			}
		}
		this.requests = tempRequests;
	}

	@track checked = false;
	handleChecked(event) {
		this.checked = event.detail.checked;
		this.showHideInactives();
	}

	showHideInactives() {
		if (this.checked) {
			this.requests = this.allRequests;
		}
		else {
			this.filterRequests();
		}
	}

	@track defaultSortDirection = 'asc';
	@track sortDirection = 'asc';
	@track sortedBy = 'StartTime__c';

	mobileSortingDefaultValue = '{"fieldName": "StartTime__c", "sortDirection": "asc"} ';
	get sortingOptions() {
		return [
			{ label: 'Start tid stigende', value: '{"fieldName": "StartTime__c", "sortDirection": "asc"} ' },
			{ label: 'Start tid synkende', value: '{"fieldName": "StartTime__c", "sortDirection": "desc"} ' },
			{ label: 'Tema A - Å', value: '{"fieldName": "Subject__c", "sortDirection": "asc"} ' },
			{ label: 'Tema Å - A', value: '{"fieldName": "Subject__c", "sortDirection": "desc"} ' },
			{ label: 'Oppmøtested A - Å', value: '{"fieldName": "MeetingStreet__c", "sortDirection": "asc"} ' },
			{ label: 'Oppmøtested Å - A', value: '{"fieldName": "MeetingStreet__c", "sortDirection": "desc"} ' },
			{ label: 'Status stigende', value: '{"fieldName": "ExternalRequestStatus__c", "sortDirection": "asc"} ' },
			{ label: 'Status synkende', value: '{"fieldName": "ExternalRequestStatus__c", "sortDirection": "desc"} ' },
		];
	}
	handleMobileSorting(event) {
		this.sortList(JSON.parse(event.detail.value));
	}


	sortBy(field, reverse, primer) {
		const key = primer
			? function (x) {
				return primer(x[field]);
			}
			: function (x) {
				return x[field];
			};
		if (field == 'ExternalRequestStatus__c') {
			return function (a, b) {
				a = key(a).toLowerCase();
				b = key(b).toLowerCase();
				a = a == "åpen" ? 0 : a == "under behandling" ? 1 : a == "tildelt" ? 2 : a == "pågår" ? 3 : a == "dekket" ?
					4 : a == "delvis dekket" ? 5 : a == "udekket" ? 6 : a == "avlyst" ? 7 : a == "avslått" ? 8 : 9;
				b = b == "åpen" ? 0 : b == "under behandling" ? 1 : b == "tildelt" ? 2 : b == "pågår" ? 3 : b == "dekket" ?
					4 : b == "delvis dekket" ? 5 : b == "udekket" ? 6 : b == "avlyst" ? 7 : b == "avslått" ? 8 : 9;
				return reverse * ((a > b) - (b > a));
			};
		}
		else {
			return function (a, b) {
				a = key(a).toLowerCase();
				b = key(b).toLowerCase();
				console.log(b);
				return reverse * ((a > b) - (b > a));
			};
		}
	}

	onHandleSort(event) {
		this.sortList(event.detail);
	}

	sortList(input) {
		const { fieldName: sortedBy, sortDirection } = input;
		const cloneData = [...this.allRequests];

		cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
		this.allRequests = cloneData;
		this.sortDirection = sortDirection;
		this.sortedBy = sortedBy;
		this.showHideInactives();
	}

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
			case 'edit_order':
				this.editOrder(row);
				break;
			default:
		}
	}
	connectedCallback() {
		refreshApex(this.wiredRequestsResult);
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
			if (this.requests[index].ExternalRequestStatus__c != "Avlyst" && this.requests[index].ExternalRequestStatus__c != "Dekket") {
				if (confirm("Er du sikker på at du vil avlyse bestillingen?")) {
					const fields = {};
					fields[REQUEST_ID.fieldApiName] = Id;
					fields[STATUS.fieldApiName] = "Avlyst";
					const recordInput = { fields };
					updateRecord(recordInput)
						.then(() => {
							refreshApex(this.wiredRequestsResult);
						})
						.catch(error => {
							alert("Kunne ikke avlyse bestilling.");

						});
				}
			}
			else {
				alert("Du kan ikke avlyse denne bestillingen");

			}
		}
	}

	cloneOrder(row) {
		const { Id } = row;
		const index = this.findRowIndexById(Id);
		if (index != -1) {

			//Here we should get the entire record from salesforce, to get entire interpretation address.
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


	editOrder(row) {
		const { Id } = row;
		const index = this.findRowIndexById(Id);
		if (index != -1) {
			if (this.requests[index].ExternalRequestStatus__c == "Åpen") {
				//Here we should get the entire record from salesforce, to get entire interpretation address.
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
						edit: true,
					}
				});
			}
			else {
				alert("Du kan ikke endre denne bestillingen");

			}
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
				pageName: 'home'
			}
		});
	}

}
