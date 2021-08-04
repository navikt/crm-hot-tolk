import { LightningElement, wire, track } from 'lwc';
import getServiceResource from '@salesforce/apex/HOT_FreelanceContactInfoController.getServiceResource';

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
}
