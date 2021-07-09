import { LightningElement, wire, track } from 'lwc';
//import getPerson from '@salesforce/apex/HOT_UserInformationController.getPerson';
import getServiceResource from '@salesforce/apex/HOT_FreelanceUserInformationController.getServiceResource';



export default class Hot_frilanstolkUserInformation extends LightningElement {
    @track ServiceResource;
    @track Name;
    @track recordId;
    // @track HOT_AddressOverride__c;
    // @track HOT_Address__c;
    // @track HOT_IsAvailableForAcuteAssignments__c;

    @wire(getServiceResource)
    wiredGetServiceResource(result) {
        if (result.data) {
            this.ServiceResource = result.data;
            this.recordId = this.ServiceResource.Id;
            this.Name = this.ServiceResource.Name;
            this.HOT_AddressOverride__c =this.ServiceResource.HOT_AddressOverride__c;
            this.HOT_Address__c = this.ServiceResource.HOT_Address__c;
            this.HOT_IsAvailableForAcuteAssignments__c = this.ServiceResource.HOT_IsAvailableForAcuteAssignments__c;
           
            //this.RelatedRecordId = this.person.Id;
        }
        console.log(getServiceResource() + "get service resource kall");
        console.log(JSON.stringify(this.ServiceResource) + " this.serviceresource");
       console.log(JSON.stringify(this.Name));
    }
}
