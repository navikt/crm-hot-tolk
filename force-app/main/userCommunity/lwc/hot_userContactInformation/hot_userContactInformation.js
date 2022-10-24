import { LightningElement, wire, track } from 'lwc';
import getPersonPhoneEmailAndStatus from '@salesforce/apex/HOT_UserInformationController.getPersonPhoneEmailAndStatus';
import { updateRecord } from 'lightning/uiRecordApi';

export default class hot_userContactInformation extends LightningElement {
    @track person;
    @track recordId;
    @wire(getPersonPhoneEmailAndStatus)
    wiredPerson(result) {
        if (result.data) {
            this.person = result.data;
            this.recordId = this.person.Id;
        }
    }

    setKrrIntegrationStatusToQueued() {
        try {
            this.person.INT_KrrIntegrationStatus__c = 'Queued';
        } catch (error) {
            console.log(error);
        }
        updateRecord({ person: this.person });
    }

    get isKrrQueued() {
        try {
            let status = this.person?.INT_KrrIntegrationStatus__c == 'Queued' ? true : false;
            console.log(status);
            return status;
        } catch (error) {
            console.log(error);
        }
    }
}
