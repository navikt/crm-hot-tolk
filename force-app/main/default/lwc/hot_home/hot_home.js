import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import NAME_FIELD from '@salesforce/schema/User.FirstName';
import checkAssignedPermissionSet from '@salesforce/apex/HOT_Utility.checkAssignedPermissionSet'

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

	@track isFrilans = false;
	@wire(checkAssignedPermissionSet, { permissionSetName: 'HOT_Tolk_Frilans' })
	wireIsFrilans({ error, data }) {
		if (data) {
			this.isFrilans = data;
		}
		console.log(this.isFrilans);
	}

	@wire(checkAssignedPermissionSet, { permissionSetName: 'HOT_Admin' }) //Use this when developing/testing
	wireIsAdmin({ error, data }) {
		if (data && !this.isFrilans) {
			this.isFrilans = data;
		}
		console.log(this.isFrilans);
	}

}