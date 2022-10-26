import { LightningElement, wire, track } from 'lwc';
import getPersonPhoneEmailAndStatus from '@salesforce/apex/HOT_UserInformationController.getPersonPhoneEmailAndStatus';
import { updateRecord } from 'lightning/uiRecordApi';
import INT_KrrIntegrationStatus__c from '@salesforce/schema/Person__ChangeEvent.INT_KrrIntegrationStatus__c';
import updateKrrStatus from '@salesforce/apex/HOT_UserInformationController.updateKrrStatus';

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
        var personCloned = JSON.parse(JSON.stringify(this.person));
        try {
            personCloned.INT_KrrIntegrationStatus__c = 'Queued';
            updateKrrStatus({ receivedPerson: personCloned });
        } catch (error) {
            console.log(error);
        }
    }

    get isKrrQueued() {
        try {
            let status = this.person?.INT_KrrIntegrationStatus__c == 'Queued' ? true : false;
            return status;
        } catch (error) {
            console.log(error);
        }
    }
}
