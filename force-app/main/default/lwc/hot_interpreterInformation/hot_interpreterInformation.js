import { LightningElement, track, wire } from 'lwc';
import checkAssignedPermissionSet from '@salesforce/apex/HOT_Utility.checkAssignedPermissionSet'
import checkAssignedPermissionSetGroup from '@salesforce/apex/HOT_Utility.checkAssignedPermissionSetGroup'
import getServiceResource from '@salesforce/apex/HOT_Utility.getServiceResource';

export default class Hot_interpreterInformation extends LightningElement {

	@track serviceResource;
	@track recordId;
	@track hasTerritories;
	@track hasSkills;
	@wire(getServiceResource)
	wiredServiceResource(result) {
		if (result.data) {
			this.recordId = result.data.Id;
			this.serviceResource = result.data;
			console.log(JSON.stringify(this.serviceResource));
			this.hasTerritories = this.serviceResource.ServiceTerritories.length > 0;
			this.hasSkills = this.serviceResource.ServiceResourceSkills.length > 0;
		}

	}

	@track isFrilans = false;
	@wire(checkAssignedPermissionSetGroup, { permissionSetGroupName: 'HOT_Tolk_Frilans_Gruppe' })
	wireIsFrilans({ error, data }) {
		if (data) {
			this.isFrilans = data;
		}
	}
	@wire(checkAssignedPermissionSet, { permissionSetName: 'HOT_Admin' }) //Use this when developing/testing
	wireIsAdmin({ error, data }) {
		if (data && !this.isFrilans) {
			this.isFrilans = data;
		}
	}

}