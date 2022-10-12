import { LightningElement, wire, track } from 'lwc';
import getPersonPhoneEmailAndStatus from '@salesforce/apex/HOT_UserInformationController.getPersonPhoneEmailAndStatus';
import INT_KrrIntegrationStatus__c from '@salesforce/schema/Person__ChangeEvent.INT_KrrIntegrationStatus__c';
import updateKrrStatusToQueued from '@salesforce/apex/HOT_UserInformationController.updateKrrStatusToQueued';

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
        //alert('test, integrasjonsstatus: ' );
        //INT_KrrIntegrationStatus__c = 'Queued';
        this.person.INT_KrrIntegrationStatus__c = 'Queued';
        updateKrrStatusToQueued(this.person)
    }

    get isKrrQueued (){
        return INT_KrrIntegrationStatus__c == 'Queued' ? true : false;
    }

}
