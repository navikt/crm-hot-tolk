import { LightningElement, wire, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getWorkOrders from '@salesforce/apex/HOT_WorkOrderListController.getWorkOrders';




var actions = [
	{ label: 'Avlys', name: 'delete' },
	{ label: 'Detaljer', name: 'details' },
];

export default class Hot_myAppointments extends NavigationMixin(LightningElement) {

	@track workOrders = [];
	@wire(getWorkOrders)
	wiredWorkOrders(result) {
		console.log("hei")
		if (result.data) {
			console.log(result.data)
			this.error = undefined;
			this.workOrders = result.data;

		} else {
			console.log(result.error)
			this.error = result.error;
			this.workOrders = undefined;
		}
	}

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
			label: 'Adresse',
			fieldName: 'Street',
			type: 'text',
			sortable: true,
		},
		{
			label: 'Postnr',
			fieldName: 'PostalCode',
			type: 'text',
			sortable: true,
		},
		{
			label: 'Poststed',
			fieldName: 'City',
			type: 'text',
			sortable: true,
		},
		{
			type: 'action',
			typeAttributes: { rowActions: actions },
		},
	];


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

	goToMyAppointments(event) {
		if (!this.isProd) {
			event.preventDefault();
			this[NavigationMixin.Navigate]({
				type: 'comm__namedPage',
				attributes: {
					pageName: 'mine-avtaler'
				}
			});
		}
	}
}