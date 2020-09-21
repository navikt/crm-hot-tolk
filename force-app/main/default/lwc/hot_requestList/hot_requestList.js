import { LightningElement, wire, track, api } from 'lwc';
import getRequestList from '@salesforce/apex/HOT_RequestListContoller.getRequestList';
import { updateRecord } from 'lightning/uiRecordApi';
import STATUS from '@salesforce/schema/HOT_Request__c.Status__c';
import REQUEST_ID from '@salesforce/schema/HOT_Request__c.Id';
import { refreshApex } from '@salesforce/apex';
import { NavigationMixin } from 'lightning/navigation';
import isProdFunction from '@salesforce/apex/GlobalCommunityHeaderFooterController.isProd';
import getAssignedResources from '@salesforce/apex/HOT_Utility.getAssignedResources';
import getPersonAccount from '@salesforce/apex/HOT_Utility.getPersonAccount';


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
	@track userRecord = { AccountId: null };
	@wire(getPersonAccount)
	wiredGetRecord({ error, data }) {
		if (data) {
			this.userRecord.AccountId = data.Id;
		}
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
			typeAttributes: { rowActions: this.getRowActions },
		},
	];
	columnLabels = ["'Start tid'", "'Slutt tid'", "'Oppmøtested'", "'Tema'", "'Status'"];

	getRowActions(row, doneCallback) {
		let actions = [];
		if (row["Orderer__c"] == row["TempAccountId__c"]) {
			if (row["Status__c"] != "Avlyst" && row["Status__c"] != "Dekket" && row["Status__c"] != "Udekket") {
				actions.push({ label: 'Avlys', name: 'delete' });
			}
			if (row["Status__c"] == "Åpen") {
				actions.push({ label: 'Rediger', name: 'edit_order' });
			}
			actions.push({ label: 'Kopier', name: 'clone_order' });
		}

		actions.push({ label: 'Detaljer', name: 'details' });

		console.log(JSON.stringify(actions));
		doneCallback(actions);

	}

	get requestTypes() {
		return [
			{ label: 'Mine bestillinger', value: 'my' },
			{ label: 'Bestillinger på vegne av andre', value: 'user' }
		];
	}


	@track rerender;
	@track requests;
	@track allRequests;
	@track allOrderedRequests;
	@track allMyRequests;
	@track error;
	wiredRequestsResult;

	@wire(getRequestList)
	async wiredRequest(result) {
		console.log("wiredRequests")
		console.log(JSON.stringify(result));
		this.wiredRequestsResult = result;
		if (result.data) {

			this.allRequests = this.distributeRequests(result.data);
			this.filterRequests();
			this.showHideInactives();
			this.error = undefined;
			//console.log(JSON.stringify(this.allRequests));
			var requestIds = [];
			for (var request of result.data) {
				requestIds.push(request.Id);
			}
			this.requestAssignedResources = await getAssignedResources({ requestIds });
			//console.log(this.requestAssignedResources);

		} else if (result.error) {
			this.error = result.error;
			this.allRequests = undefined;
		}
	}

	distributeRequests(data) {
		this.allMyRequests = [];
		this.allOrderedRequests = [];
		for (let request of data) {
			if (request.Account__c == this.userRecord.AccountId) {
				this.allMyRequests.push(request);
			}
			else if (request.Orderer__c == this.userRecord.AccountId && request.Account__c != this.userRecord.AccountId) {
				this.allOrderedRequests.push(request);
			}
		}
		return this.isMyRequests ? this.allMyRequests : this.allOrderedRequests;
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
	@track isMyRequests = true;
	handleRequestType(event) {
		this.isMyRequests = event.detail.value == 'my';
		this.allRequests = this.isMyRequests ? this.allMyRequests : this.allOrderedRequests;
		this.filterRequests();
		this.showHideInactives();
		let tempColumns = [...this.columns];
		let tempColumnLabels = [...this.columnLabels];
		if (this.isMyRequests) {
			tempColumns.shift();
			tempColumnLabels.shift();
			tempColumnLabels.push("''");
		}
		else {
			tempColumns.unshift({ label: 'Bruker', fieldName: 'UserName__c', type: 'text', sortable: true, })
			tempColumnLabels.unshift("'Bruker'");
		}
		for (var i = 0; i < tempColumnLabels.length; i++) {
			document.documentElement.style.setProperty('--columnlabel_' + i.toString(), tempColumnLabels[i]);
		}
		this.columns = [...tempColumns];
		this.columnLabels = [...tempColumnLabels];
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
					copy: true,
				}
			});
		}
	}


	editOrder(row) {
		const { Id } = row;
		const index = this.findRowIndexById(Id);
		if (index != -1) {
			if (row.Orderer__c == this.userRecord.AccountId) {
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
			}
			else {
				alert("Denne bestillingen er bestilt av noen andre, og du har ikke rettigheter til å endre den.")
			}
		}
	}
	@track interpreters = [];
	@track showInterpreters = false;
	@track isDetails = false;
	@track record = null;
	@track userForm = false;
	@track myRequest = false;
	@track companyForm = false;
	@track publicEvent = false;
	showDetails(row) {
		this.record = row;
		console.log(JSON.stringify(this.record));

		this.myRequest = this.record.Orderer__c == this.userRecord.AccountId;
		this.userForm = this.record.Type__c == 'User' || this.record.Type__c == 'Company';
		this.companyForm = this.record.Type__c == 'Company' || this.record.Type__c == 'PublicEvent';
		this.publicEvent = this.record.Type__c == 'PublicEvent';

		this.interpreters = [];
		if (this.requestAssignedResources[row.Id] != null) {
			for (var interpreter of this.requestAssignedResources[row.Id]) {
				this.interpreters.push(interpreter);
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
