import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import NAME_FIELD from '@salesforce/schema/User.FirstName';
import checkAssignedPermissionSet from '@salesforce/apex/HOT_Utility.checkAssignedPermissionSet'
import checkAssignedPermissionSetGroup from '@salesforce/apex/HOT_Utility.checkAssignedPermissionSetGroup'
import isProdFunction from '@salesforce/apex/GlobalCommunityHeaderFooterController.isProd';

export default class Hot_home extends NavigationMixin(LightningElement) {

	@track isProd;
	@track error;
	@wire(isProdFunction)
	wiredIsProd({ error, data }) {
		this.isProd = data;
		//console.log("isProd: " + this.isProd);
	}

	@track name;
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

	connectedCallback() {
		window.scrollTo(0, 1);
		window.scrollTo(0, 0);
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

	goToNewRequest(event) {
		if (!this.isProd) {
			event.preventDefault();
			this[NavigationMixin.Navigate]({
				type: 'comm__namedPage',
				attributes: {
					pageName: 'ny-bestilling'
				},
			});
		}
	}

	goToMyPage(event) {
		if (!this.isProd) {
			event.preventDefault();
			this[NavigationMixin.Navigate]({
				type: 'comm__namedPage',
				attributes: {
					pageName: 'min-side'
				},
			});
		}
	}

	@track isFrilans = false;
	@wire(checkAssignedPermissionSetGroup, { permissionSetGroupName: 'HOT_Tolk_Frilans_Gruppe' })
	async wireIsFrilans({ error, data }) {
		this.isFrilans = data;


	}
	@wire(checkAssignedPermissionSet, { permissionSetName: 'HOT_Admin' }) //Use this when developing/testing
	wireIsAdmin({ error, data }) {
		if (!this.isFrilans) {
			this.isFrilans = data;
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

	goToOppdrag(event) {
		if (!this.isProd) {
			event.preventDefault();
			this[NavigationMixin.Navigate]({
				type: 'comm__namedPage',
				attributes: {
					pageName: 'mine-oppdrag'
				},
			});
		}
	}



}
