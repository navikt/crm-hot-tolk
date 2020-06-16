import { LightningElement, wire, track, api } from 'lwc';
import getInterestedResources from '@salesforce/apex/HOT_InterestedResourcesListController.getInterestedResources';
import getServiceResource from '@salesforce/apex/HOT_Utility.getServiceResource';
import { refreshApex } from '@salesforce/apex';
import retractInterests from '@salesforce/apex/HOT_InterestedResourcesListController.retractInterests';
import resendInterestApex from '@salesforce/apex/HOT_InterestedResourcesListController.resendInterest';
import addComment from '@salesforce/apex/HOT_InterestedResourcesListController.addComment';
import readComment from '@salesforce/apex/HOT_InterestedResourcesListController.readComment';


var actions = [
	{ label: 'Kommenter', name: 'comment' },
	{ label: 'Send Interesse', name: 'resendInterest' },
];

export default class Hot_interestedResourcesList extends LightningElement {

	@track columns = [

		{
			label: 'Oppdragsnummer',
			fieldName: 'Name',
			type: 'text',
			sortable: true,
		},
		{
			label: 'Tid',
			fieldName: 'ServiceAppointmentTime__c',
			type: 'text',
			sortable: true,
		},
		{
			label: 'Adresse',
			fieldName: 'ServiceAppointmentAddress__c',
			type: 'text',
			sortable: true,
		},
		{
			label: 'Status',
			fieldName: 'Status__c',
			type: 'text',
			sortable: true,
		},
		{
			label: 'Ny kommentar',
			fieldName: 'IsNewComment__c',
			type: 'boolean',
		},
		{
			type: 'action',
			typeAttributes: { rowActions: actions },
		},
	];
	columnLabels = ["'Oppdragsnummer'", "''", "'Tid'", "'Adresse'", "'Status'", "'Ny kommentar'"];


	@track serviceResource;
	@wire(getServiceResource)
	wiredServiceresource(result) {
		if (result.data) {
			this.serviceResource = result.data;
			console.log(JSON.stringify(this.serviceResource));
		}
	}

	@track interestedResources;
	@track interestedResourcesFiltered;
	wiredInterestedResourcesResult;
	@wire(getInterestedResources)
	wiredInterestedResources(result) {
		this.wiredInterestedResourcesResult = result;
		if (result.data) {
			this.interestedResources = result.data;
			this.error = undefined;
			this.filterInterestedResources();
			this.showHideAll();
			//console.log(JSON.stringify(this.interestedResources));

		} else if (result.error) {
			this.error = result.error;
			this.interestedResources = undefined;
		}
	}
	filterInterestedResources() {
		var tempInterestedResources = [];
		for (var i = 0; i < this.interestedResources.length; i++) {
			if (this.interestedResources[i].Status__c == "Interested") {
				tempInterestedResources.push(this.interestedResources[i]);
			}
		}
		this.interestedResourcesFiltered = tempInterestedResources;
	}

	showHideAll() {
		if (this.isChecked) {
			this.interestedResourcesFiltered = this.interestedResources;
		}
		else {
			this.filterInterestedResources();
		}
	}

	connectedCallback() {

		for (var i = 0; i < this.columnLabels.length; i++) {
			document.documentElement.style.setProperty('--columnlabel_' + i.toString(), this.columnLabels[i]);
		}
		refreshApex(this.wiredInterestedResourcesResult);
	}

	//Sorting methods
	@track defaultSortDirection = 'asc';
	@track sortDirection = 'asc';
	@track sortedBy = 'EarliestStartTime';

	mobileSortingDefaultValue = '{"fieldName": "EarliestStartTime", "sortDirection": "asc"} ';
	get sortingOptions() {
		return [
			{ label: 'Oppdragsnummer stigende', value: '{"fieldName": "Name", "sortDirection": "asc"} ' },
			{ label: 'Oppdragsnummer synkende', value: '{"fieldName": "Name", "sortDirection": "desc"} ' },
			{ label: 'Tid stigende', value: '{"fieldName": "ServiceAppointmentTime__c", "sortDirection": "asc"} ' },
			{ label: 'Tid synkende', value: '{"fieldName": "ServiceAppointmentTime__c", "sortDirection": "desc"} ' },
			{ label: 'Adresse A - Å', value: '{"fieldName": "ServiceAppointmentAddress__c", "sortDirection": "asc"} ' },
			{ label: 'Adresse Å - A', value: '{"fieldName": "ServiceAppointmentAddress__c", "sortDirection": "desc"} ' },
			{ label: 'Status A - Å', value: '{"fieldName": "Status__c", "sortDirection": "asc"} ' },
			{ label: 'Status Å - A', value: '{"fieldName": "Status__c", "sortDirection": "desc"} ' },
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
		let cloneData = [...this.interestedResources];
		cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));

		this.interestedResources = cloneData;
		this.sortDirection = sortDirection;
		this.sortedBy = sortedBy;
		this.showHideAll();
	}

	//Row action methods
	handleRowAction(event) {
		const actionName = event.detail.action.name;
		const row = event.detail.row;
		switch (actionName) {
			case 'comment':
				this.openComments(row);
				break;
			case 'resendInterest':
				this.resendInterest(row);
				break;
			default:
		}
	}

	@track subject = "Ingen detaljer";
	@track isAddComments = false;
	@track recordId;
	@track prevComments = ["Ingen tidligere kommentarer"];
	openComments(row) {
		this.isAddComments = true;
		this.subject = row.ServiceAppointment__r.HOT_FreelanceSubject__c;
		this.recordId = row.Id;
		this.prevComments = row.Comments__c.split("\n\n");

		let interestedResourceId = this.recordId;
		console.log(interestedResourceId);
		readComment({ interestedResourceId })
			.then(() => {
				refreshApex(this.wiredInterestedResourcesResult);
			});
	}
	closeComments() {
		this.isAddComments = false;
	}
	sendComment() {
		let interestedResourceId = this.recordId;
		var newComment = this.template.querySelector(".newComment").value;
		addComment({ interestedResourceId, newComment })
			.then(() => {
				refreshApex(this.wiredInterestedResourcesResult);
			});
		this.isAddComments = false;
	}

	//Move this to apex to avoid sharing settings
	resendInterest(row) {
		const interestedId = row.Id;
		if (row.Status__c == "Retracted Interest") {
			if (confirm("Er du sikker på at du vil melde interesse for oppdraget?")) {
				resendInterestApex({ interestedId })
					.then(() => {
						refreshApex(this.wiredInterestedResourcesResult);
					})
					.catch(error => {
						console.log(error);
						alert("Kunne ikke sende interesse.");
					});
			}
		}
		else { alert("Du kan ikke sende interesse for dette oppdraget"); }
	}

	@track selectedRows = [];
	getSelectedName(event) {
		this.selectedRows = event.detail.selectedRows;
	}

	isChecked = false;
	@track checkBoxLabel = "Vis lukkede oppdrag";
	handleChecked(event) {
		this.isChecked = event.detail.checked;
		if (this.isChecked) {
			//this.checkBoxLabel = "Vis oppdrag fra mine regioner";
			this.interestedResourcesFiltered = this.interestedResources;
		}
		else {
			//this.checkBoxLabel = "Vis oppdrag fra alle regioner";
			this.filterInterestedResources();
		}
	}
	retractInterest() {
		if (this.selectedRows.length > 0) {
			let retractionIds = [];
			for (var i = 0; i < this.selectedRows.length; i++) {
				retractionIds.push(this.selectedRows[i].Id);
			}
			//console.log(retractionIds);
			if (confirm("Er du sikker på at du vil tilbaketrekke interesse for valgte oppdrag?")) {
				retractInterests({ retractionIds })
					.then(() => {
						refreshApex(this.wiredInterestedResourcesResult);
					});
			}
		}
		else {
			alert("Velg oppdrag du ønsker å tilbaketrekke interesse for, så trykk på knappen.");
		}

	}


}