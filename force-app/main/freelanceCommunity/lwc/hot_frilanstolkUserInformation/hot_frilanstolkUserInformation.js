import { LightningElement, wire, track } from 'lwc';
import getServiceResource from '@salesforce/apex/HOT_FreelanceUserInformationController.getServiceResource';

export default class Hot_frilanstolkUserInformation extends LightningElement {
    @track serviceResource;
    @track name;
    @track recordId;
    @wire(getServiceResource)
    wiredGetServiceResource(result) {
        if (result.data) {
            this.serviceResource = result.data;
            this.recordId = this.serviceResource.Id;
            this.name = this.serviceResource.Name;
            this.HOT_AddressOverride__c = this.serviceResource.HOT_AddressOverride__c;
            this.HOT_Address__c = this.serviceResource.HOT_Address__c;
            this.HOT_IsAvailableForAcuteAssignments__c = this.serviceResource.HOT_IsAvailableForAcuteAssignments__c;
        }
    }
}
