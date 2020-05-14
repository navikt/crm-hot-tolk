import { LightningElement, wire, track, api } from 'lwc';
import getMyServiceAppointments from '@salesforce/apex/HOT_MyServiceAppointmentListController.getMyServiceAppointments';


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