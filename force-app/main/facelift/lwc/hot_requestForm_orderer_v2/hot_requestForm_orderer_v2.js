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
    handleDontNotifyUserCheckbox(event) {
        this.fieldValues.IsNotNotifyAccount__c = event.detail;
    }

    @track fieldValues = {
        OrdererEmail__c: '',
        OrdererPhone__c: '',
        IsOrdererWantStatusUpdateOnSMS__c: false,
        IsNotNotifyAccount__c: false
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

    ordererPhoneError = 'Bestillers telefon må fylles ut.';

    validateOrdererPhone(inputCmp, errMsg, validateStartingNumber) {
        let num = inputCmp.getValue().replaceAll(' ', '');
        let hasError = false;

        if (num.substring(0, 4) === '0047' && num.length === 12) {
            num = num.substring(4, num.length);
        }
        if (num.charAt(0) === '+') {
            hasError = true;
        }
        if (num.substring(0, 3) === '+47') {
            if (num.length < 11) {
                hasError = true;
            }
            num = num.substring(3, num.length);
        }
        if (isNaN(num)) {
            hasError = true;
        }
        if (num.length !== 8) {
            hasError = true;
        }
        if (validateStartingNumber && num.charAt(0) !== '4' && num.charAt(0) !== '9') {
            hasError = true;
        }

        inputCmp.sendErrorMessage(hasError ? errMsg : '');
        return hasError;
    }

    @api
    validateFields() {
        this.ordererPhoneError = this.fieldValues.IsOrdererWantStatusUpdateOnSMS__c
            ? 'Bestillers telefon må være et gyldig mobilnummer hvis ønske om SMS-varsel ved statusendring er valgt.'
            : 'Bestillers telefon må være et gyldig telefonnummer.';
        let hasErrors = false;
        this.template.querySelectorAll('c-input').forEach((element) => {
            if (element.validationHandler()) {
                hasErrors += 1;
            }
        });
        const ordererPhoneInput = this.template.querySelectorAll('c-input')[2];
        hasErrors += this.validateOrdererPhone(
            ordererPhoneInput,
            this.ordererPhoneError,
            this.fieldValues.IsOrdererWantStatusUpdateOnSMS__c
        )
            ? 1
            : 0;
        return hasErrors;
    }

    @api
    getFieldValues() {
        return this.fieldValues;
    }

    @api parentFieldValues;
    connectedCallback() {
        this.showDiv = true;
        setTimeout(() => this.template.querySelector('h2').focus());

        for (let field in this.parentFieldValues) {
            if (this.fieldValues[field] != null) {
                this.fieldValues[field] = this.parentFieldValues[field];
            }
        }
    }

    // renderedCallback() {
    //     this.template.querySelector('h2').focus();
    // }
}
