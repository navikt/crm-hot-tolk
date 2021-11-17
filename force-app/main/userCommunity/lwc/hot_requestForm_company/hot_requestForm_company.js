import { LightningElement, track, api } from 'lwc';
import { organizationNumberValidationRules } from './hot_validationRules';
import { validate } from 'c/validationController';

export default class Hot_requestForm_company extends LightningElement {
    @api checkboxValue = false;
    @track fieldValues = {
        OrganizationNumber__c: '',
        InvoiceReference__c: '',
        IsOtherEconomicProvicer__c: false,
        AdditionalInvoiceText__c: ''
    };
    choices = [
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
        this.template.querySelectorAll('c-input').forEach((element) => {
            this.fieldValues[element.name] = element.getValue();
        });
    }
    // TODO: Set picklist value on back button pressed
    // Note: Proves to be hard as array in picklist is immutable at this stage. Probably same problem for radiobuttons and checkbox?
    // Error: Invalid mutation: Cannot set "selected" on "[object Object]". "[object Object]" is read-only.
    /*getPicklistValue() {
        const selectedEvent = new CustomEvent('getpicklistvalue', {
            detail: this.template.querySelector('c-picklist').getValue()
        });
        this.dispatchEvent(selectedEvent);
    }*/

    attemptedSubmit = false;
    @api
    validateFields() {
        this.attemptedSubmit = true;
        // TODO: Fix org number validation
        let hasErrors = validate(
            this.template.querySelector('[data-id="orgnumber"]'),
            organizationNumberValidationRules
        );
        if (this.template.querySelector('c-picklist').validationHandler()) {
            hasErrors += 1;
        }
        return hasErrors;
    }

    @api
    getFieldValues() {
        //this.getPicklistValue();
        return this.fieldValues;
    }

    @api picklistValuePreviouslySet;
    @api parentFieldValues;
    connectedCallback() {
        for (let field in this.parentFieldValues) {
            if (this.fieldValues[field] != null) {
                this.fieldValues[field] = this.parentFieldValues[field];
            }
        }
    }

    renderedCallback() {
        this.template.querySelector('c-checkbox').setCheckboxValue(this.checkboxValue);
        this.userCheckboxValue = this.checkboxValue;
        if (this.picklistValuePreviouslySet !== undefined) {
            this.template.querySelector('c-picklist').setValue(this.picklistValuePreviouslySet.label);
        }
    }
}
