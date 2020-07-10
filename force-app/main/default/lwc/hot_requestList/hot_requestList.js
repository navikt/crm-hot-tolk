import { LightningElement, wire, track, api } from 'lwc';
import getRequestList from '@salesforce/apex/HOT_RequestListContoller.getRequestList';
import { updateRecord } from 'lightning/uiRecordApi';
import STATUS from '@salesforce/schema/HOT_Request__c.Status__c';
import REQUEST_ID from '@salesforce/schema/HOT_Request__c.Id';
import { refreshApex } from '@salesforce/apex';
import { NavigationMixin } from 'lightning/navigation';
import isProdFunction from '@salesforce/apex/GlobalCommunityHeaderFooterController.isProd';


var actions = [
	{ label: 'Avlys', name: 'delete' },
	{ label: 'Kopier', name: 'clone_order' },
	{ label: 'Rediger', name: 'edit_order' },
	{ label: 'Detaljer', name: 'details' },
];
export default class RequestList extends NavigationMixin(LightningElement) {
	@track isProd;
	@track error;
	@wire(isProdFunction)
	wiredIsProd({ error, data }) {
		this.isProd = data;
	}
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
	columnLabels = ["'Start tid'", "'Slutt tid'", "'Oppmøtested'", "'Tema'", "'Status'"];


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
			//console.log(JSON.stringify(this.allRequests));
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


	sortBy(field, reverse) {
		const key = function (x) {
			return x[field];
		};
		const valueStatus = ["åpen", "under behandling", "tildelt", "pågår", "dekket", "delvis dekket", "udekket", "avlyst", "avslått"];
		if (field == 'ExternalRequestStatus__c') {
			return function (a, b) {
				a = key(a).toLowerCase();
				b = key(b).toLowerCase();
				a = valueStatus.indexOf(a);
				b = valueStatus.indexOf(b);
				//console.log(a + ", " + b);
				//console.log(reverse * ((a > b) - (b > a)));
				return reverse * ((a > b) - (b > a));
			};
		}
		else {
			return function (a, b) {
				a = key(a).toLowerCase();
				b = key(b).toLowerCase();
				//console.log(a + ", " + b);
				//console.log(reverse * ((a > b) - (b > a)));
				return reverse * ((a > b) - (b > a));
			};
		}
	}

	onHandleSort(event) {
		this.sortList(event.detail);
	}

	sortList(input) {
		const { fieldName: sortedBy, sortDirection } = input;
		let cloneData = [...this.allRequests];
		//console.log("sortedBy: " + sortedBy + ", sortDirection: " + sortDirection);
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
			case 'details':
				this.showDetails(row);
				break;
			default:
		}
	}
	connectedCallback() {
		for (var i = 0; i < this.columnLabels.length; i++) {
			document.documentElement.style.setProperty('--columnlabel_' + i.toString(), this.columnLabels[i]);
		}
		window.scrollTo(0, 0);
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
	@track interpreters = [];
	@track showInterpreters = false;
	@track isDetails = false;
	@track record = null;
	showDetails(row) {
		this.record = row;
		this.interpreters = [];
		if (row.ServiceAppointments__r != null) {
			var serviceAppointments = row.ServiceAppointments__r;
			for (var sa of serviceAppointments) {
				if (sa.HOT_ServiceResource__c != null) {
					this.interpreters.push(sa.HOT_ServiceResource__r.Name);
				}
			}
			if (this.interpreters.length > 0) {
				this.showInterpreters = true;
			}
		}
		this.isDetails = true;
	}

	abortShowDetails() {
		this.isDetails = false;
		this.showInterpreters = false;
	}


	goToMyRequests(event) {
		if (!this.isProd) {
			event.preventDefault();
			this[NavigationMixin.Navigate]({
				type: 'comm__namedPage',
				attributes: {
					pageName: 'mine-bestillinger'
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
	goToHome(event) {
		if (!this.isProd) {
			event.preventDefault();
			this[NavigationMixin.Navigate]({
				type: 'comm__namedPage',
				attributes: {
					pageName: 'home'
				},
			});
		}
	}

}
