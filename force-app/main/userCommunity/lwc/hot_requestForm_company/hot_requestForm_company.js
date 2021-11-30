import { LightningElement, track, api } from 'lwc';
export default class Hot_requestForm_company extends LightningElement {
    @api checkboxValue = false;
    @api isEditMode = false;
    @track fieldValues = {
        OrganizationNumber__c: '',
        InvoiceReference__c: '',
        IsOtherEconomicProvicer__c: false,
        AdditionalInvoiceText__c: ''
    };
    choices = [
        { name: 'Placeholder', label: 'Velg et alternativ', selected: true },
        { name: 'NAV', label: 'NAV betaler' },
        { name: 'Virksomhet', label: 'Virksomhet betaler' }
    ];

    handlePicklist(event) {
        this.fieldValues.IsOtherEconomicProvicer__c = event.detail.name === 'Virksomhet';
        this.sendPicklistValue(event.detail.name);
        if (event.detail.name === 'NAV') {
            this.fieldValues.InvoiceReference__c = '';
            this.fieldValues.AdditionalInvoiceText__c = '';
        }
    }

    handleUserCheckbox(event) {
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

    sendPicklistValue(selectedPicklistName) {
        const selectedEvent = new CustomEvent('getpicklistvalue', {
            detail: selectedPicklistName
        });
        this.dispatchEvent(selectedEvent);
    }

    setPicklistValue() {
        if (this.picklistValuePreviouslySet === undefined || this.picklistValuePreviouslySet === null) {
            return;
        }
        this.choices.forEach((element) => {
            element.selected = false;
            if (element.name === this.picklistValuePreviouslySet) {
                element.selected = true;
            }
        });
    }

    @api
    validateFields() {
        let hasErrors = 0;
        if (this.template.querySelectorAll('c-input')[0].validateOrgNumber()) {
            hasErrors += 1;
        }
        if (this.template.querySelector('c-picklist').validationHandler()) {
            hasErrors += 1;
        }
        return hasErrors;
    }

    @api
    getFieldValues() {
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
        this.setPicklistValue();
    }
}
