import { LightningElement, track, wire } from 'lwc';
import getServiceResource from '@salesforce/apex/HOT_FreelanceUserInformationController.getServiceResource';

export default class Hot_frilanstolkUserInformation extends LightningElement {
    @track serviceResource;
    @track recordId;
    @wire(getServiceResource)
    wiredGetServiceResource(result) {
        if (result.data) {
            this.serviceResource = result.data;
            this.recordId = this.serviceResource.Id;
        }
    }
    viewUserInformation = true;
    editUserInformation = false;
    editProfile() {
        this.viewUserInformation = false;
        this.editUserInformation = true;
    }
    handleAbort() {
        this.viewUserInformation = true;
        this.editUserInformation = false;
    }
    handleSubmit() {
        this.template.querySelector('lightning-record-edit-form').submit();
    }
    handleError() {}
    handleSuccess() {
        this.viewUserInformation = true;
        this.editUserInformation = false;
    }
}
