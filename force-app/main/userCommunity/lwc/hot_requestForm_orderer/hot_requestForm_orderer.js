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

    handleSMSCheckbox(event) {
        this.fieldValues.IsOrdererWantStatusUpdateOnSMS__c = event.detail;
    }

    @track fieldValues = {
        OrdererEmail__c: '',
        OrdererPhone__c: '',
        IsOrdererWantStatusUpdateOnSMS__c: false
    };

    @api
    setFieldValues() {
        this.template.querySelectorAll('c-input').forEach((element) => {
            this.fieldValues[element.name] = element.getValue();
        });
        this.template.querySelectorAll('c-checkbox').forEach((element) => {
            this.fieldValues[element.name] = element.getValue();
        });
    }

    ordererPhoneError = 'Feltet må fylles ut.';
    @api
    validateFields() {
        this.ordererPhoneError = 'Feltet må fylles ut.';
        let hasErrors = false;
        this.template.querySelectorAll('c-input').forEach((element) => {
            if (element.validationHandler()) {
                hasErrors += 1;
            }
        });
        if (
            this.template.querySelectorAll('c-input')[2].validatePhone() &&
            this.fieldValues.IsOrdererWantStatusUpdateOnSMS__c
        ) {
            this.ordererPhoneError =
                'Bestillers telefon må være et mobilnummer hvis ønske om SMS-varsel ved statusendring er huket av.';
            hasErrors += 1;
        }
        return hasErrors;
    }

    @api
    getFieldValues() {
        return this.fieldValues;
    }

    @api parentFieldValues;
    connectedCallback() {
        for (let field in this.parentFieldValues) {
            if (this.fieldValues[field] != null) {
                this.fieldValues[field] = this.parentFieldValues[field];
            }
        }
    }
}
