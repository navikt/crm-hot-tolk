import { LightningElement, wire, track } from 'lwc';
import getServiceResource from '@salesforce/apex/HOT_FreelanceUserInformationController.getServiceResource';

export default class Hot_frilanstolkUserInformation extends LightningElement {
    @track ServiceResource;
    @track recordId;
    @wire(getServiceResource)
    wiredGetServiceResource(result) {
        if (result.data) {
            this.ServiceResource = result.data;
            this.recordId = this.ServiceResource.Id;
        }
    }
}
