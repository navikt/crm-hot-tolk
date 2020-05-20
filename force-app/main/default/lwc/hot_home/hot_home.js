import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import NAME_FIELD from '@salesforce/schema/User.FirstName';

export default class Hot_home extends NavigationMixin(LightningElement) {


	@track name;
	@track error;
	@wire(getRecord, {
		recordId: USER_ID,
		fields: [NAME_FIELD]
	}) wireuser({
		error,
		data
	}) {
		if (error) {
			this.error = error;
		} else if (data) {
			this.name = data.fields.FirstName.value;

		}
	}

	@track isProd = window.location.toString().includes("tolkebestilling.nav.no/");

}