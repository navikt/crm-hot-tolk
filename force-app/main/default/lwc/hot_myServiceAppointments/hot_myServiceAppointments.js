import { LightningElement, wire, track, api } from 'lwc';
import getMyServiceAppointments from '@salesforce/apex/HOT_MyServiceAppointmentListController.getMyServiceAppointments';
import getServiceResource from '@salesforce/apex/HOT_Utility.getServiceResource';
import { refreshApex } from '@salesforce/apex';
import getMyServiceAppointmentFieldHistories from '@salesforce/apex/HOT_MyServiceAppointmentListController.getMyServiceAppointmentFieldHistories';
import getParentWorkOrderLineItems from '@salesforce/apex/HOT_MyServiceAppointmentListController.getParentWorkOrderLineItems'

var actions = [
	{ label: 'Detaljer', name: 'details' },
];


export default class Hot_myServiceAppointments extends LightningElement {

	connectedCallback() {
		for (var i = 0; i < this.columnLabels.length; i++) {
			document.documentElement.style.setProperty('--columnlabel_' + i.toString(), this.columnLabels[i]);
		}
	}

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
			label: 'Status',
			fieldName: 'Status',
			type: 'text',
			sortable: true,
		},
		{
			type: 'action',
			typeAttributes: { rowActions: actions },
		},
	];
	columnLabels = ["'Oppdragsnummer'", "'Tid'", "'Adresse'", "'Status'"];

	@track serviceResource;
	@wire(getServiceResource)
	wiredServiceresource(result) {
		if (result.data) {
			this.serviceResource = result.data;
		}
	}

	@track workOrderLineItems;
	@wire(getParentWorkOrderLineItems)
	wiredWorkOrderLineItems(result) {
		console.log("wiredWorkOrderLineItems");
		if (result.data) {
			this.workOrderLineItems = result.data;
			console.log(JSON.stringify(this.workOrderLineItems));
		}
		if (this.myServiceAppointments != null && this.workOrderLineItems != null) {
			this.insertAssignemtType();
		}
	}

	@track myServiceAppointments;
	@track myServiceAppointmentsFiltered;
	wiredMyServiceAppointmentsResult;
	@wire(getMyServiceAppointments)
	wiredMyServiceAppointments(result) {
		console.log("wiredMyServiceAppointments");
		this.wiredMyServiceAppointmentsResult = result;
		if (result.data) {
			this.myServiceAppointments = result.data;
			this.error = undefined;
			console.log(JSON.stringify(this.myServiceAppointments));
			this.filterServiceAppointments();
			console.log(JSON.stringify(this.myServiceAppointmentsFiltered));
		} else if (result.error) {
			this.error = result.error;
			this.myServiceAppointments = undefined;
		}
		if (this.myServiceAppointments != null && this.workOrderLineItems != null) {
			this.insertAssignemtType();
		}
	}

	assignmentTypes = {};
	insertAssignemtType() {
		console.log("insertAssignemtType");
		for (var i = 0; i < this.myServiceAppointments.length; i++) {
			for (var j = 0; j < this.workOrderLineItems.length; j++) {
				if (this.myServiceAppointments[i].ParentRecordId == this.workOrderLineItems[j].Id) {
					var id = this.myServiceAppointments[i].Id
					this.assignmentTypes[id] = this.workOrderLineItems[j].WorkOrder.HOT_Request__r.AssignmentType__c;
				}
			}
		}
		console.log(JSON.stringify(this.assignmentTypes));
	}

	filterServiceAppointments() {
		console.log("filterServiceAppointments");
		var tempServiceAppointments = [];
		for (var i = 0; i < this.myServiceAppointments.length; i++) {
			if (this.myServiceAppointments[i].Status != 'Avbrutt' && this.myServiceAppointments[i].Status != 'Kan ikke fullføre' && this.myServiceAppointments[i].Status != 'Fullført') {
				tempServiceAppointments.push(this.myServiceAppointments[i]);
			}
		}
		this.myServiceAppointmentsFiltered = tempServiceAppointments;
	}

	showHideAll() {
		if (this.isChecked) {
			this.myServiceAppointmentsFiltered = this.myServiceAppointments;
		}
		else {
			this.filterServiceAppointments();
		}
	}

	//Sorting methods
	@track defaultSortDirection = 'asc';
	@track sortDirection = 'asc';
	@track sortedBy = 'EarliestStartTime';

	mobileSortingDefaultValue = '{"fieldName": "EarliestStartTime", "sortDirection": "asc"} ';
	get sortingOptions() {
		return [
			{ label: 'Oppdragsnummer stigende', value: '{"fieldName": "AppointmentNumber", "sortDirection": "asc"} ' },
			{ label: 'Oppdragsnummer synkende', value: '{"fieldName": "AppointmentNumber", "sortDirection": "desc"} ' },
			{ label: 'Tid stigende', value: '{"fieldName": "HOT_DateTimeFormated__c", "sortDirection": "asc"} ' },
			{ label: 'Tid synkende', value: '{"fieldName": "HOT_DateTimeFormated__c", "sortDirection": "desc"} ' },
			{ label: 'Adresse A - Å', value: '{"fieldName": "HOT_AddressFormated__c", "sortDirection": "asc"} ' },
			{ label: 'Adresse Å - A', value: '{"fieldName": "HOT_AddressFormated__c", "sortDirection": "desc"} ' },
			{ label: 'Status A - Å', value: '{"fieldName": "Status", "sortDirection": "asc"} ' },
			{ label: 'Status Å - A', value: '{"fieldName": "Status", "sortDirection": "desc"} ' },
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
		let cloneData = [...this.myServiceAppointments];
		cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));

		this.myServiceAppointments = cloneData;
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

	@track recordId;
	@track statusHistoryUserId;
	@track statusChangedDate;
	@track statusHistoryRecordId;
	@track formidlerId;
	@track formidlerRecordId;
	@track assignmentType;
	@track isDetails = false;
	@track testing = false;
	showDetails(row) {
		console.log("showDetails");
		this.recordId = row.Id;
		var serviceAppointmentId

		var history = getMyServiceAppointmentFieldHistories({ serviceAppointmentId });
		this.assignmentType = this.assignmentTypes[this.recordId];
		/*
		for (var i = 0; i < history.Status.length; i++) {
			if (history.Status[i].ServiceAppointmentId == this.recordId) {
				this.statusHistoryRecordId = history.Status[i].Id;
				this.statusHistoryUserId = history.Status[i].CreatedById;
				this.statusChangedDate = history.Status[i].CreatedDate;
			}
		}
		for (var i = 0; i < history.HOT_TermsOfAgreement__c.length; i++) {
			if (history.HOT_TermsOfAgreement__c[i].ServiceAppointmentId == this.recordId) {
				this.formidlerId = history.HOT_TermsOfAgreement__c[i].CreatedById;
				this.formidlerRecordId = history.HOT_TermsOfAgreement__c[i].Id;
				console.log(this.formidlerId);
			}
		}
		*/
		this.isDetails = true;

	}
	abortShowDetails() {
		this.isDetails = false;
	}

	isChecked = false;
	handleChecked(event) {
		this.isChecked = event.detail.checked;
		if (this.isChecked) {
			this.myServiceAppointmentsFiltered = this.myServiceAppointments;
		}
		else {
			this.filterServiceAppointments();
		}
	}


}