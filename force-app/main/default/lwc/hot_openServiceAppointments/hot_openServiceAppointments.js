import { LightningElement, wire, track, api } from 'lwc';
import getOpenServiceAppointments from '@salesforce/apex/HOT_OpenServiceAppointmentListController.getOpenServiceAppointments';
import getServiceResource from '@salesforce/apex/HOT_Utility.getServiceResource';
import { refreshApex } from '@salesforce/apex';
import createInterestedResources from '@salesforce/apex/HOT_OpenServiceAppointmentListController.createInterestedResources';



var actions = [
	{ label: 'Detaljer', name: 'details' },
];

export default class Hot_allServiceAppointments extends LightningElement {



	@track columns = [
		{
			label: 'Oppdragsnummer',
			fieldName: 'AppointmentNumber',
			type: 'text',
			sortable: true,
		},
		{
			label: 'Tid',
			fieldName: 'HOT_DateTimeFormated__c',
			type: 'Text',
			sortable: true,
		},
		{
			label: 'Adresse',
			fieldName: 'HOT_AddressFormated__c',
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
			label: 'Påmeldte',
			fieldName: 'HOT_NumberOfInterestedResources__c',
			type: 'number',
			sortable: true,
			cellAttributes: { alignment: 'left' }
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

	columnLabels = ["'Tid'", "''", "'Adresse'", "'Arbeidstype'", "'Påmeldte'", "'Frist"];

	@track serviceResource;
	@wire(getServiceResource)
	wiredServiceresource(result) {
		if (result.data) {
			this.serviceResource = result.data;
			console.log(JSON.stringify(this.serviceResource));
		}
	}

	@track allServiceAppointments;
	@track allServiceAppointmentsFiltered;
	wiredAllServiceAppointmentsResult;
	@wire(getOpenServiceAppointments)
	wiredAllServiceAppointments(result) {
		this.wiredAllServiceAppointmentsResult = result;
		if (result.data) {
			this.allServiceAppointments = result.data;
			this.error = undefined;
			this.filterServiceAppointments();
			this.showHideAll();
			//console.log(JSON.stringify(this.allServiceAppointments));
			for (var i = 0; i < this.allServiceAppointments.length; i++) {
				//console.log(JSON.stringify(this.allServiceAppointments[i].WorkType));
			}
		} else if (result.error) {
			this.error = result.error;
			this.allServiceAppointments = undefined;
		}
	}
	filterServiceAppointments() {
		var tempServiceAppointments = [];
		for (var i = 0; i < this.allServiceAppointments.length; i++) {
			if (this.serviceResource.ServiceTerritories && JSON.stringify(this.serviceResource.ServiceTerritories).includes(this.allServiceAppointments[i].ServiceTerritoryId)) {
				tempServiceAppointments.push(this.allServiceAppointments[i]);
			}
		}
		this.allServiceAppointmentsFiltered = tempServiceAppointments;
	}

	showHideAll() {
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
	@track sortDirection = 'asc';
	@track sortedBy = 'EarliestStartTime';

	mobileSortingDefaultValue = '{"fieldName": "EarliestStartTime", "sortDirection": "asc"} ';
	get sortingOptions() {
		return [
			{ label: 'Tid stigende', value: '{"fieldName": "HOT_DateTimeFormated__c", "sortDirection": "asc"} ' },
			{ label: 'Tid synkende', value: '{"fieldName": "HOT_DateTimeFormated__c", "sortDirection": "desc"} ' },
			{ label: 'Adresse A - Å', value: '{"fieldName": "HOT_AddressFormated__c", "sortDirection": "asc"} ' },
			{ label: 'Adresse Å - A', value: '{"fieldName": "HOT_AddressFormated__c", "sortDirection": "desc"} ' },
			{ label: 'Arbeidstype A - Å', value: '{"fieldName": "HOT_WorkTypeName__c", "sortDirection": "asc"} ' },
			{ label: 'Arbeidstype Å - A', value: '{"fieldName": "HOT_WorkTypeName__c", "sortDirection": "desc"} ' },
			{ label: 'Antall påmeldte stigende', value: '{"fieldName": "HOT_NumberOfInterestedResources__c", "sortDirection": "asc"} ' },
			{ label: 'Antall påmeldte synkende', value: '{"fieldName": "HOT_NumberOfInterestedResources__c", "sortDirection": "desc"} ' },
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

	@track subject = "Ingen ytterligere informasjon";
	@track isDetails = false;
	showDetails(row) {
		const { Id } = row;
		if (row.HOT_FreelanceSubject__c) {
			this.subject = row.HOT_FreelanceSubject__c;
		}
		this.isDetails = true;
	}
	abortShowDetails() {
		this.isDetails = false;
		this.subject = "Ingen ytterligere informasjon";
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


}