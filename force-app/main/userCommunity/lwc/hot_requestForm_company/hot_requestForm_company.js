import { LightningElement, track, api } from 'lwc';
import { organizationNumberValidationRules } from './hot_validationRules';
import { validate } from 'c/validationController';

export default class Hot_requestForm_company extends LightningElement {
    @track fieldValues = {
        OrganizationNumber__c: '',
        InvoiceReference__c: '',
        IsOtherEconomicProvicer__c: false,
        AdditionalInvoiceText__c: ''
    };
    choices = [
        { name: '', label: 'Velg et alternativ' },
        { name: 'NAV', label: 'NAV betaler' },
        { name: 'Virksomhet', label: 'Virksomhet betaler' }
    ];

    handlePicklist(event) {
        this.fieldValues.IsOtherEconomicProvicer__c = event.detail.name === 'Virksomhet';
    }
    userCheckboxValue = false;
    handleUserCheckbox(event) {
        this.userCheckboxValue = event.detail;
        const selectedEvent = new CustomEvent('usercheckboxclicked', {
            detail: event.detail
        });
        this.dispatchEvent(selectedEvent);
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
        let hasErrors = validate(
            this.template.querySelector('[data-id="orgnumber"]'),
            organizationNumberValidationRules
        );
        let picklistValidation = this.template.querySelector('c-picklist').validationHandler();
        console.log('picklistValidation: ', picklistValidation);
        if (picklistValidation) {
            console.log('picklist error');
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

    handleNextButtonClicked() {
        if (!this.validateFields()) {
            console.log('hallo');
            const selectedEvent = new CustomEvent('nextbuttonclicked', {
                detail: 'companyformcomplete'
            });
            this.dispatchEvent(selectedEvent);
        }
    }
}
