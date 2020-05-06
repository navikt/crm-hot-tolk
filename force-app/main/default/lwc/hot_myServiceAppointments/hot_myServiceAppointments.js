import { LightningElement, wire, track, api } from 'lwc';
import getAllServiceAppointments from '@salesforce/apex/HOT_ServiceAppointmentListControllerAll.getAllServiceAppointments';
import getMyServiceAppointments from '@salesforce/apex/HOT_ServiceAppointmentListControllerMy.getMyServiceAppointments';
import getServiceResource from '@salesforce/apex/HOT_getServiceResource.getServiceResource';
import createServiceConnection from '@salesforce/apex/HOT_CreateInterestedResource.createInterestedResource';
import { createRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import { NavigationMixin } from 'lightning/navigation';

export default class Hot_myServiceAppointments extends LightningElement {

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
}