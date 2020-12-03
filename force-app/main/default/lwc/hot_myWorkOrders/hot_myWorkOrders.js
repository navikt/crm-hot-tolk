import { LightningElement, wire, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import STATUS from '@salesforce/schema/WorkOrder.Status';
import { updateRecord } from 'lightning/uiRecordApi';
import WORKORDER_ID from '@salesforce/schema/WorkOrder.Id';
import getWorkOrdersFromRequest from '@salesforce/apex/HOT_WorkOrderListController.getWorkOrdersFromRequest';
import getMyWorkOrders from '@salesforce/apex/HOT_WorkOrderListController.getMyWorkOrders';
import { sortList, getMobileSortingOptions } from 'c/sortController';




var actions = [
	{ label: 'Avlys', name: 'delete' }
];

export default class Hot_myWorkOrders extends NavigationMixin(LightningElement) {


	@track columns = [
		{
			label: 'Start tid',
			fieldName: 'StartDate',
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
			fieldName: 'EndDate',
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
			label: 'Tema',
			fieldName: 'Subject',
			type: 'text',
			sortable: true,
		},
		{
			label: 'Bestillingsnummer',
			fieldName: 'HOT_RequestName__c',
			type: 'text',
			sortable: true,
		},
		{
			label: 'Status',
			fieldName: 'HOT_ExternalWorkOrderStatus__c',
			type: 'text',
			sortable: true,
		},
		{
			label: 'Tolker',
			fieldName: 'HOT_Interpreters__c',
			type: 'text',
			sortable: true,
		}
		/*
		{
			type: 'action',
			typeAttributes: { rowActions: actions },
		},
		*/
	];

	@track workOrders = [];
	@track requestNumber;
	@track showAll = true;
	connectedCallback() {
		let testURL = window.location.href;
		let params = testURL.split("?")[1];

		function parse_query_string(query) {
			var vars = query.split("&");
			var query_string = {};
			for (var i = 0; i < vars.length; i++) {
				var pair = vars[i].split("=");
				var key = decodeURIComponent(pair[0]);
				var value = decodeURIComponent(pair[1]);
				// If first entry with this name
				if (typeof query_string[key] === "undefined") {
					query_string[key] = decodeURIComponent(value);
					// If second entry with this name
				} else if (typeof query_string[key] === "string") {
					var arr = [query_string[key], decodeURIComponent(value)];
					query_string[key] = arr;
					// If third or later entry with this name
				} else {
					query_string[key].push(decodeURIComponent(value));
				}
			}
			return query_string;
		}

		if (params != undefined) {
			var parsed_params = parse_query_string(params);
			let requestNumber = parsed_params.id;
			if (parsed_params.id != null) {
				this.requestNumber = parsed_params.id;
			}
			console.log("getWorkOrdersFromRequest")
			console.log(requestNumber)
			getWorkOrdersFromRequest({ requestNumber: requestNumber }).then(result => {
				this.workOrders = result;
			});
			this.showAll = false;
		}
		else {
			console.log("getMyWorkOrders")
			this.showAll = true;
			getMyWorkOrders().then(result => {
				this.workOrders = result;
			});
		}
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

	goToMyWorkOrders(event) {
		if (!this.isProd) {
			event.preventDefault();
			this[NavigationMixin.Navigate]({
				type: 'comm__namedPage',
				attributes: {
					pageName: 'min-tidsplan'
				}
			});
		}
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
	@track thisURL = window.location.href;


	@track defaultSortDirection = 'asc';
	@track sortDirection = 'asc';
	@track sortedBy = 'StartDate';

	mobileSortingDefaultValue = '{"fieldName": "StartDate", "sortDirection": "asc"} ';
	get sortingOptions() {
		return getMobileSortingOptions(this.columns)
	}
	handleMobileSorting(event) {
		this.sortDirection = event.detail.value.sortDirection;
		this.sortedBy = event.detail.value.fieldName;
		this.workOrders = sortList(this.workOrders, this.sortedBy, this.sortDirection);
	}
	onHandleSort(event) {
		this.sortDirection = event.detail.sortDirection;
		this.sortedBy = event.detail.fieldName;
		this.workOrders = sortList(this.workOrders, this.sortedBy, this.sortDirection);
	}

	handleRowAction(event) {
		const actionName = event.detail.action.name;
		const row = event.detail.row;

		switch (actionName) {
			case 'delete':
				this.cancelWorkOrder(row);
				break;
		}
	}
	cancelWorkOrder(row) {
		const { Id } = row;
		console.log(JSON.stringify(this.workOrders))
		const index = this.findRowIndexById(Id);
		console.log(index)
		if (index != -1) {
			console.log("index != -1")
			if (this.workOrders[index].HOT_ExternalWorkOrderStatus__c != "Avlyst" && this.workOrders[index].HOT_ExternalWorkOrderStatus__c != "Dekket") {
				console.log("confirm")
				if (confirm("Er du sikker på at du vil avlyse?")) {
					const fields = {};
					fields[WORKORDER_ID.fieldApiName] = Id;
					fields[STATUS.fieldApiName] = "Avlyst";
					const recordInput = { fields };
					updateRecord(recordInput)
						.then(() => {
							refreshApex(this.workOrders);
						})
						.catch(error => {
							alert("Kunne ikke avlyse.");

						});
				}
			}
			else {
				alert("Du kan ikke avlyse denne bestillingen.");
			}
		}
	}
	findRowIndexById(Id) {
		let ret = -1;
		this.workOrders.some((row, index) => {
			if (row.Id === Id) {
				ret = index;
				return true;
			}
			return false;
		});
		return ret;
	}

}