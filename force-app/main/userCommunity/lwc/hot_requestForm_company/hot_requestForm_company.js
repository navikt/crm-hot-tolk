import { LightningElement, track, api } from 'lwc';
import { organizationNumberValidationRules } from './hot_validationRules';
import { validate } from 'c/validationController';

export default class Hot_requestForm_company extends LightningElement {
    //TODO: Why is not economic provider added as field here?
    @track fieldValues = {
        OrganizationNumber__c: '',
        InvoiceReference__c: '',
        AdditionalInvoiceText__c: ''
    };
    choices = [
        { name: 'Default', label: 'Velg et alternativ' }, // TODO: Figure out what to do here. Placeholder?
        { name: 'NAV', label: 'NAV betaler' },
        { name: 'Virksomhet', label: 'Virksomhet betaler' }
    ];

    isCompanyEconomicProvider = false;
    handlePicklist(event) {
        this.isCompanyEconomicProvider = event.detail.name === 'Virksomhet';
    }

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

    @api parentFieldValues;
    connectedCallback() {
        for (let field in this.parentFieldValues) {
            if (this.fieldValues[field] != null) {
                this.fieldValues[field] = this.parentFieldValues[field];
            }
        }
    }
}
