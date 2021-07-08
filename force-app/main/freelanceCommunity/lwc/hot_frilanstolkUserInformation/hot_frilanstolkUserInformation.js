import { LightningElement, wire, track } from 'lwc';
//import getPerson from '@salesforce/apex/HOT_UserInformationController.getPerson';
import getServiceResource from '@salesforce/apex/HOT_FreelanceUserInformationController.getServiceResource';



export default class Hot_frilanstolkUserInformation extends LightningElement {
    @track ServiceResource;
    @track Name;
   // @track RelatedRecordId;
    @wire(getServiceResource)
    wiredGetServiceResource(result) {
        if (result.data) {
            this.ServiceResource = result.data;
            this.Name = this.ServiceResource.Name;
           
            //this.RelatedRecordId = this.person.Id;
        }
        console.log(getServiceResource() + "get service resource kall");
        console.log(JSON.stringify(this.ServiceResource) + " this.serviceresource");
       console.log(JSON.stringify(this.Name));
    }
}
