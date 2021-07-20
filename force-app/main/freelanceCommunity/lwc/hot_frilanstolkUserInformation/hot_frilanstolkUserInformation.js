import { LightningElement, track, wire, api } from 'lwc';
import getServiceResource from '@salesforce/apex/HOT_FreelanceUserInformationController.getServiceResource';

export default class Hot_frilanstolkUserInformation extends LightningElement {
    @api hot_frilanstolkEditProfile;
    @track serviceResource;
    @track recordId;
    @wire(getServiceResource)
    wiredGetServiceResource(result) {
        if (result.data) {
            this.serviceResource = result.data;
            this.recordId = this.serviceResource.Id;
        }
    }
}
