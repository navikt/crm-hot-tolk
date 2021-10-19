import { LightningElement, track } from 'lwc';

export default class Hot_requestForm_company extends LightningElement {
    @track OrganizationNumber__c = '';
    @track InvoiceReference__c = '';
    @track AdditionalInvoiceText__c = '';

    checkOrganizationNumber(event) {
        //Return if wrong format? ExpReg
    }
}
