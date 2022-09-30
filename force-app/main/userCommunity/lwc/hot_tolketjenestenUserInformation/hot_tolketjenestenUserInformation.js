import { LightningElement, wire, track, api } from 'lwc';
import getPerson from '@salesforce/apex/HOT_UserInformationController.getPerson';

export default class hot_tolketjenestenUserInformation extends LightningElement {
    @track person;
    @track recordId;
    @track options;
    @track selectedOption;
    @wire(getPerson)
    wiredGetPerson(result) {
        if (result.data) {
            this.person = result.data;
            this.recordId = this.person.Id;
            this.selectedOption = this.person.HOT_NotificationChannel__c;
        }
    }
}
