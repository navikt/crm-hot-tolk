import { LightningElement, wire, track, api } from 'lwc';
import getOpenServiceAppointments from '@salesforce/apex/HOT_OpenServiceAppointmentListController.getOpenServiceAppointments';
import getServiceResource from '@salesforce/apex/HOT_Utility.getServiceResource';
import { refreshApex } from '@salesforce/apex';
import createInterestedResources from '@salesforce/apex/HOT_OpenServiceAppointmentListController.createInterestedResources';


var actions = [
	{ label: 'Detaljer', name: 'details' },
];

export default class Hot_openServiceAppointments extends LightningElement {



	@track columns = [
		{
			label: 'Frigitt dato',
			fieldName: 'HOT_ReleaseDate__c',
			type: 'date',
			sortable: true,
			typeAttributes: {
				day: 'numeric',
				month: 'numeric',
				year: 'numeric'
			}
		},
		{
			label: 'Start Tid',
			fieldName: 'EarliestStartTime',
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
			label: 'Slutt Tid',
			fieldName: 'DueDate',
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
			label: 'Poststed',
			fieldName: 'City',
			type: 'text',
			sortable: true,
		},
		{
			label: 'Tema',
			fieldName: 'HOT_FreelanceSubject__c',
			type: 'text',
			sortable: true,
		},
		{
			label: 'Arbeidstype',
			fieldName: 'HOT_WorkTypeName__c',
			type: 'text',
			sortable: true,
		},
		{
			label: 'Frist',
			fieldName: 'HOT_DeadlineDate__c',
			type: 'date',
			sortable: true,
			typeAttributes: {
				day: 'numeric',
				month: 'numeric',
				year: 'numeric',
			}
		},
		{
			type: 'action',
			typeAttributes: { rowActions: actions },
		},
	];

	columnLabels = ["'Frigitt Dato'", "''", "'Start Tid'", "'Slutt Tid'", "'Poststed'", "'Tema'", "'Arbeidstype'", "'Frist"];

	@track serviceResource;
	@wire(getServiceResource)
	wiredServiceresource(result) {
		if (result.data) {
			this.serviceResource = result.data;
			console.log(JSON.stringify(this.serviceResource));
			let tempRegions = result.data.HOT_PreferredRegions__c.split(';');
			for (let tempRegion of tempRegions) {
				this.regions.push(tempRegion);
			}
		}
	}

	@track allServiceAppointments;
	@track allServiceAppointmentsFiltered;
	wiredAllServiceAppointmentsResult;
	@wire(getOpenServiceAppointments)
	wiredAllServiceAppointments(result) {
		//console.log("wiredAllServiceAppointments");
		this.wiredAllServiceAppointmentsResult = result;
		if (result.data) {
			this.allServiceAppointments = result.data;
			this.error = undefined;
			this.filterServiceAppointments();
			this.showHideAll();
			console.log("JSON.stringify(this.allServiceAppointments):");
			console.log(JSON.stringify(this.allServiceAppointments));
			console.log("JSON.stringify(this.allServiceAppointmentsFiltered):");
			console.log(JSON.stringify(this.allServiceAppointmentsFiltered));
		} else if (result.error) {
			this.error = result.error;
			console.log(this.error);
			this.allServiceAppointments = undefined;
		}
	}
	filterServiceAppointments() {
		console.log("filterServiceAppointments");
		var tempServiceAppointments = [];
		for (var i = 0; i < this.allServiceAppointments.length; i++) {
			if (this.regions.includes(this.allServiceAppointments[i].ServiceTerritory.HOT_DeveloperName__c)) {
				tempServiceAppointments.push(this.allServiceAppointments[i]);
			}
		}
		this.allServiceAppointmentsFiltered = tempServiceAppointments;
	}

	showHideAll() {
		console.log("showHideAll");
		if (this.isChecked) {
			this.allServiceAppointmentsFiltered = this.allServiceAppointments;
		}
		else {
			this.filterServiceAppointments();
		}
	}

	connectedCallback() {
		for (var i = 0; i < this.columnLabels.length; i++) {
			document.documentElement.style.setProperty('--columnlabel_' + i.toString(), this.columnLabels[i]);
		}

		refreshApex(this.wiredAllServiceAppointmentsResult);
	}
	//Sorting methods
	@track defaultSortDirection = 'asc';
	@track sortDirection = 'desc';
	@track sortedBy = 'HOT_ReleaseDate__c';

	mobileSortingDefaultValue = '{"fieldName": "HOT_ReleaseDate__c", "sortDirection": "desc"} ';
	get sortingOptions() {
		return [
			{ label: 'Frigitt dato stigende', value: '{"fieldName": "HOT_ReleaseDate__c", "sortDirection": "asc"} ' },
			{ label: 'Frigitt dato synkende', value: '{"fieldName": "HOT_ReleaseDate__c", "sortDirection": "desc"} ' },
			{ label: 'Start tid stigende', value: '{"fieldName": "EarliestStartTime", "sortDirection": "asc"} ' },
			{ label: 'Start tid synkende', value: '{"fieldName": "EarliestStartTime", "sortDirection": "desc"} ' },
			{ label: 'Slutt tid stigende', value: '{"fieldName": "DueDate", "sortDirection": "asc"} ' },
			{ label: 'Slutt tid synkende', value: '{"fieldName": "DueDate", "sortDirection": "desc"} ' },
			{ label: 'Poststed A - Å', value: '{"fieldName": "City", "sortDirection": "asc"} ' },
			{ label: 'Poststed A - Å', value: '{"fieldName": "City", "sortDirection": "desc"} ' },
			{ label: 'Arbeidstype A - Å', value: '{"fieldName": "HOT_WorkTypeName__c", "sortDirection": "asc"} ' },
			{ label: 'Arbeidstype Å - A', value: '{"fieldName": "HOT_WorkTypeName__c", "sortDirection": "desc"} ' },
			{ label: 'Tema A - Å', value: '{"fieldName": "HOT_FreelanceSubject__c", "sortDirection": "asc"} ' },
			{ label: 'Tema A - Å', value: '{"fieldName": "HOT_FreelanceSubject__c", "sortDirection": "desc"} ' },
			{ label: 'Frist dato stigende', value: '{"fieldName": "HOT_DeadlineDate__c", "sortDirection": "asc"} ' },
			{ label: 'Frist dato synkende', value: '{"fieldName": "HOT_DeadlineDate__c", "sortDirection": "desc"} ' },
		];
	}
	handleMobileSorting(event) {
		this.sortList(JSON.parse(event.detail.value));
	}
	sortBy(field, reverse) {
		const key = function (x) {
			return x[field];
		};
		if (field == 'HOT_NumberOfInterestedResources__c') {
			return function (a, b) {
				a = key(a);
				b = key(b);
				return reverse * ((a > b) - (b > a));
			};
		}
		else {
			return function (a, b) {
				a = key(a).toLowerCase();
				b = key(b).toLowerCase();
				return reverse * ((a > b) - (b > a));
			};
		}
	}
	onHandleSort(event) {
		this.sortList(event.detail);
	}
	sortList(input) {
		const { fieldName: sortedBy, sortDirection } = input;
		let cloneData = [...this.allServiceAppointments];
		cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));

		this.allServiceAppointments = cloneData;
		this.sortDirection = sortDirection;
		this.sortedBy = sortedBy;
		this.showHideAll();
	}


	//Row action methods
	handleRowAction(event) {
		const actionName = event.detail.action.name;
		const row = event.detail.row;
		switch (actionName) {
			case 'details':
				this.showDetails(row);
				break;
			default:
		}
	}

	@track isDetails = false;
	@track serviceAppointmentDetails = null;
	showDetails(row) {
		const { Id } = row;
		this.serviceAppointmentDetails = row;
		this.isDetails = true;
	}
	abortShowDetails() {
		this.isDetails = false;
	}

	@track selectedRows = [];
	getSelectedName(event) {
		this.selectedRows = event.detail.selectedRows;
		console.log(JSON.stringify(this.selectedRows));
	}

	@track isAddComments = false;
	abortSendingInterest() {
		this.isAddComments = false;
	}
	sendInterest() {
		if (this.selectedRows.length > 0) {
			this.isAddComments = true;
		}
		else {
			alert("Velg oppdrag du ønsker å melde interesse om, så trykk på knappen.");
		}
	}
	confirmSendingInterest() {

		let serviceAppointmentIds = [];
		let comments = [];
		for (var i = 0; i < this.selectedRows.length; i++) {
			serviceAppointmentIds.push(this.selectedRows[i].Id);
		}
		this.template.querySelectorAll("lightning-input-field")
			.forEach(element => {
				comments.push(element.value);
			});
		createInterestedResources({ serviceAppointmentIds, comments })
			.then(() => {
				refreshApex(this.wiredAllServiceAppointmentsResult);
			});
		this.isAddComments = false;
		//location.reload();

	}

	isChecked = false;
	@track checkBoxLabel = "Vis oppdrag fra alle regioner";
	handleChecked(event) {
		this.isChecked = event.detail.checked;
		if (this.isChecked) {
			//this.checkBoxLabel = "Vis oppdrag fra mine regioner";
			this.allServiceAppointmentsFiltered = this.allServiceAppointments;
		}
		else {
			//this.checkBoxLabel = "Vis oppdrag fra alle regioner";
			this.filterServiceAppointments();
		}
	}
	@track showRegionFilter = false;
	@track regions = [];
	handleShowRegionFilter(event) {
		this.showRegionFilter = !this.showRegionFilter;
	}
	handleSubmit(event) {
		event.preventDefault();
		const fields = event.detail.fields;
		this.regions = fields.HOT_PreferredRegions__c;
		this.filterServiceAppointments();
		this.template.querySelector('lightning-record-edit-form').submit(this.fieldValues);
		this.handleHideRegionFilter();
	}
	handleHideRegionFilter() {
		this.showRegionFilter = !this.showRegionFilter;
	}
	savePrefferedRegions() {
		this.handleHideRegionFilter();
	}


}