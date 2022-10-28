import { LightningElement, track, wire } from 'lwc';
import getServiceResource from '@salesforce/apex/HOT_FreelanceUserInformationController.getServiceResource';
export default class Hot_frilanstolkPreferences extends LightningElement {
    @track serviceResource;
    @track preferences;
    @track recordId;
    @wire(getServiceResource)
    wiredGetServiceResource(result) {
        if (result.data) {
            this.serviceResource = result.data;
            this.preferences = this.serviceResource.HOT_MoreInformation__c;
            this.recordId = this.serviceResource.Id;
        }
    }
    viewUserPreference = true;
    editUserPreference = false;

    editUserPreferenceBtn() {
        this.viewUserPreference = false;
        this.editUserPreference = true;
    }
    handleAbort() {
        this.viewUserPreference = true;
        this.editUserPreference = false;
    }
    handleSubmit() {
        this.template.querySelector('lightning-record-edit-form').submit();
        this.viewUserPreference = true;
        this.editUserPreference = false;
    }
}
