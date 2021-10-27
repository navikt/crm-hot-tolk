import { LightningElement, track, api } from 'lwc';
import { organizationNumberValidationRules } from './hot_validationRules';
import { validate } from 'c/validationController';

export default class Hot_requestForm_company extends LightningElement {
    @track fieldValues = {
        OrganizationNumber__c: '',
        InvoiceReference__c: '',
        AdditionalInvoiceText__c: ''
    };

    @api
    setFieldValues() {
        this.template.querySelectorAll('.tolk-skjema-input').forEach((element) => {
            this.fieldValues[element.name] = element.value;
        });
    }

    attemptedSubmit = false;
    @api
    validateFields() {
        this.attemptedSubmit = true;
        return validate(this.template.querySelector('[data-id="orgnumber"]'), organizationNumberValidationRules);
    }

    @api
    getFieldValues() {
        return this.fieldValues;
    }
}
