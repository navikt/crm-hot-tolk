import { LightningElement, track, wire, api } from 'lwc';
import getPersonAccount from '@salesforce/apex/HOT_Utility.getPersonAccount';
import getOrdererDetails from '@salesforce/apex/HOT_Utility.getOrdererDetails';

export default class Hot_requestForm_orderer extends LightningElement {
    @track personAccount = { Id: '', Name: '' };
    @track ordererDetails = { OrdererEmail__c: '', OrdererPhone__c: '' };

    @wire(getPersonAccount)
    wiredGetPersonAccount(result) {
        if (result.data) {
            this.personAccount.Id = result.data.AccountId;
            this.personAccount.Name = result.data.Account.CRM_Person__r.CRM_FullName__c;
        }
    }
    @wire(getOrdererDetails)
    wiredGetOrdererDetails(result) {
        if (result.data) {
            this.ordererDetails = result.data;
        }
    }

    IsOrdererWantStatusUpdateOnSMS__c = false;

    handleSMSCheckbox(event) {
        this.IsOrdererWantStatusUpdateOnSMS__c = event.detail;
    }

    @api
    handleSubmit() {}
}
