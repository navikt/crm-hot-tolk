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
    @track viewUserInformation = true;
    @track editUserInformation = false;
    editProfile() {
        this.viewUserInformation = false;
        this.editUserInformation = true;
    }
    handleSubmit() {
        this.template.querySelector('lightning-record-edit-form').submit();
        this.viewUserInformation = true;
        this.editUserInformation = false;
    }
}
