import { LightningElement, track, wire, api } from 'lwc';
import getServiceResource from '@salesforce/apex/HOT_FreelanceUserInformationController.getServiceResource';

export default class Hot_frilanstolkEditProfile extends LightningElement {
    @api resultCallback;
    @track serviceResource;
    @track recordId;
    @wire(getServiceResource)
    wiredGetServiceResource(result) {
        if (result.data) {
            this.serviceResource = result.data;
            this.recordId = this.serviceResource.Id;
        }
    }
    updateProfileOnClick() {
        this.resultCallback();
    }
}
