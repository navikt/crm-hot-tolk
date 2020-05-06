import { LightningElement, wire, track, api } from 'lwc';
import getAllServiceAppointments from '@salesforce/apex/HOT_ServiceAppointmentListControllerAll.getAllServiceAppointments';
import getMyServiceAppointments from '@salesforce/apex/HOT_ServiceAppointmentListControllerMy.getMyServiceAppointments';
import createServiceConnection from '@salesforce/apex/HOT_CreateInterestedResource.createInterestedResource';
import { createRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import { NavigationMixin } from 'lightning/navigation';

var actions = [
	{ label: 'Detaljer', name: 'details' },
	{ label: 'Chat', name: 'chat' },
];

export default class Hot_frilanstolkServiceAppointmentLists extends NavigationMixin(LightningElement) {

	@track columns = [
		{
			label: 'Start tid',
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
			label: 'Slutt tid',
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
			label: 'Arbeidstype',
			fieldName: 'HOT_WorkTypeName__c',
			type: 'text',
			sortable: true,
		},/*
		{
			label: 'WorkType.Name',
			fieldName: 'WorkType.Name',
			type: 'text',
			sortable: true,
		},*/
		{
			label: 'Adresse',
			fieldName: 'HOT_InterpretationStreet__c',
			type: 'text',
			sortable: true,
		},
		{
			label: 'Postnr',
			fieldName: 'HOT_InterpretationPostalCode__c',
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
			type: 'action',
			typeAttributes: { rowActions: actions },
		},
	];


	@track allServiceAppointments;
	wiredAllServiceAppointmentsResult;
	@wire(getAllServiceAppointments)
	wiredAllServiceAppointments(result) {
		this.wiredAllServiceAppointmentsResult = result;
		if (result.data) {
			this.allServiceAppointments = result.data;
			this.error = undefined;
			for (var i = 0; i < this.allServiceAppointments.length; i++) {
				console.log(JSON.stringify(this.allServiceAppointments[i].WorkType.Name));
			}
		} else if (result.error) {
			this.error = result.error;
			this.allServiceAppointments = undefined;
		}
	}
	@track myServiceAppointments;
	wiredMyServiceAppointmentsResult;
	@wire(getMyServiceAppointments)
	wiredMyServiceAppointments(result) {
		this.wiredMyServiceAppointmentsResult = result;
		if (result.data) {
			this.myServiceAppointments = result.data;
			this.error = undefined;
		} else if (result.error) {
			this.error = result.error;
			this.myServiceAppointments = undefined;
		}

	}

	@track defaultSortDirection = 'asc';
	@track sortDirection = 'asc';
	@track sortedBy = 'SchedStartTime';

	mobileSortingDefaultValue = '{"fieldName": "SchedStartTime", "sortDirection": "asc"} ';
	get sortingOptions() {
		return [
			{ label: 'Start tid stigende', value: '{"fieldName": "SchedStartTime", "sortDirection": "asc"} ' },
			{ label: 'Start tid synkende', value: '{"fieldName": "SchedStartTime", "sortDirection": "desc"} ' },
			{ label: 'Tema A - Å', value: '{"fieldName": "Subject", "sortDirection": "asc"} ' },
			{ label: 'Tema Å - A', value: '{"fieldName": "Subject", "sortDirection": "desc"} ' },
			{ label: 'Sted A - Å', value: '{"fieldName": "HOT_InterpretationStreet__c", "sortDirection": "asc"} ' },
			{ label: 'Sted Å - A', value: '{"fieldName": "HOT_InterpretationStreet__c", "sortDirection": "desc"} ' },
		];
	}
	handleMobileSorting(event) {
		this.sortList(JSON.parse(event.detail.value));
	}
	sortBy(field, reverse) {
		const key = function (x) {
			return x[field];
		};

		return function (a, b) {
			a = key(a).toLowerCase();
			b = key(b).toLowerCase();
			return reverse * ((a > b) - (b > a));
		};
	}
	onHandleSort(event) {
		this.sortList(event.detail);
	}
	sortList(input) {
		const { fieldName: sortedBy, sortDirection } = input;
		let cloneData = [...this.serviceAppointments];
		cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));

		this.serviceAppointments = cloneData;
		this.sortDirection = sortDirection;
		this.sortedBy = sortedBy;
	}

	handleRowAction(event) {
		const actionName = event.detail.action.name;
		const row = event.detail.row;

		switch (actionName) {
			case 'details':
				this.showDetails(row);
				break;
			case 'chat':
				this.openChatter(row);
				break;
			default:
		}
	}
	connectedCallback() {
		refreshApex(this.wiredServiceAppointmentsResult);
	}

	showDetails(row) {

	}
	openChatter(row) {

	}

	@track selectedRows = [];
	getSelectedName(event) {
		console.log(JSON.stringify(event.detail.selectedRows));
		this.selectedRows = event.detail.selectedRows;
	}
	sendOffer() {
		if (this.selectedRows.length > 0) {
			for (var i = 0; i < this.selectedRows.length; i++) {
				HOT_CreateServiceConnection.createServiceConnection(this.selectedRows[i].AppointmentNumber);
			}
		}
	}

}

