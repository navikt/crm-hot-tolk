import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import NAME_FIELD from '@salesforce/schema/User.FirstName';
import checkAssignedPermissionSet from '@salesforce/apex/HOT_Utility.checkAssignedPermissionSet'
import checkAssignedPermissionSetGroup from '@salesforce/apex/HOT_Utility.checkAssignedPermissionSetGroup'
import checkUserHasEntitlement from '@salesforce/apex/HOT_Utility.checkUserHasEntitlement';
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
	goToRequestOnBehalf(event) {
		if (!this.isProd) {
			event.preventDefault();
			this[NavigationMixin.Navigate]({
				type: 'comm__namedPage',
				attributes: {
					pageName: 'ny-bestilling'
				},
				state: {
					notDefault: true,
				}
			});
		}
	}

	@track isFrilans = false;
	@track isTolkUser = true;
	@track isUser = false;

	@track showFrilans = false;
	@track showTolkUser = false;
	@track showUser = false;
	@wire(checkAssignedPermissionSetGroup, { permissionSetGroupName: 'HOT_Tolk_Frilans_Gruppe' })
	async wireIsFrilans({ error, data }) {
		this.isFrilans = data;
		this.isTolkUser = await checkUserHasEntitlement();
		this.isUser = !this.isTolkUser && !this.isFrilans;
		if (this.isFrilans) {
			this.showFrilans = true;
		}
		else if (this.isTolkUser == true) {
			this.showTolkUser = true;
		}
		else {
			this.showUser = true;
		}

		console.log("isFrilans: " + this.isFrilans);
		console.log("isTolkUser: " + this.isTolkUser);
		console.log("isUser: " + this.isUser);
		console.log("showFrilans: " + this.showFrilans);
		console.log("showTolkUser: " + this.showTolkUser);
		console.log("showUser: " + this.showUser);


	}
	@wire(checkAssignedPermissionSet, { permissionSetName: 'HOT_Admin' }) //Use this when developing/testing
	wireIsAdmin({ error, data }) {
		if (!this.isFrilans) {
			this.isFrilans = data;
			this.isTolkUser = true; //checkUserHasEntitlement();
			this.isUser = !this.isTolkUser && !this.isFrilans;
			if (this.isFrilans) {
				this.showFrilans = true;
			}
			else if (this.isTolkUser) {
				this.showTolkUser = true;
			}
			else {
				this.showUser = true;
			}
		}
	}


	@track showChoices = false;
	handleShowChoices() {
		this.showChoices = !this.showChoices;
	}

	changeToFreelance() {
		this.showFrilans = true;
		this.showTolkUser = false;
		this.showUser = false;
	}
	changeToTolkUser() {
		this.showFrilans = false;
		this.showTolkUser = true;
		this.showUser = false;
	}
	changeToUser() {
		this.showFrilans = false;
		this.showTolkUser = false;
		this.showUser = true;
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
