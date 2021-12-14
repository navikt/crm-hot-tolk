import { LightningElement, track, api } from 'lwc';
export default class Hot_requestForm_company extends LightningElement {
    @api isEditOrCopyMode = false;
    @track fieldValues = {
        OrganizationNumber__c: '',
        InvoiceReference__c: '',
        IsOtherEconomicProvicer__c: false,
        AdditionalInvoiceText__c: '',
        UserName__c: ''
    };
    @api parentCompanyComponentValues;
    @track componentValues = {
        choices: [
            { name: 'Placeholder', label: 'Velg et alternativ', selected: true },
            { name: 'NAV', label: 'NAV betaler' },
            { name: 'Virksomhet', label: 'Virksomhet betaler' }
        ],
        checkboxValue: false
    };

    setComponentValuesOnEditAndCopy() {
        this.componentValues.choices.forEach((element) => {
            element.selected = false;
        });
        this.componentValues.choices[1].selected = !this.fieldValues.IsOtherEconomicProvicer__c;
        this.componentValues.choices[2].selected = this.fieldValues.IsOtherEconomicProvicer__c;
        this.componentValues.checkboxValue = this.fieldValues.UserName__c !== '';
    }

    @api getComponentValues() {
        return this.componentValues;
    }

    handlePicklist(event) {
        this.componentValues.choices.forEach((element) => {
            element.selected = false;
            if (element.name === event.detail.name) {
                element.selected = true;
            }
        });
        this.fieldValues.IsOtherEconomicProvicer__c = event.detail.name === 'Virksomhet';
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
        this.componentValues.checkboxValue = event.detail;
    }

    @api
    setFieldValues() {
        this.template.querySelectorAll('c-input').forEach((element) => {
            this.fieldValues[element.name] = element.getValue();
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
        delete this.fieldValues.UserName__c;
        return this.fieldValues;
    }

    isEditOrCopyMode = false;
    @api parentFieldValues;
    connectedCallback() {
        for (let field in this.parentFieldValues) {
            if (this.fieldValues[field] != null) {
                this.fieldValues[field] = this.parentFieldValues[field];
            }
        }
        for (let field in this.parentCompanyComponentValues) {
            if (this.componentValues[field] != null) {
                this.componentValues[field] = JSON.parse(JSON.stringify(this.parentCompanyComponentValues[field]));
            }
        }
        if (this.isEditOrCopyMode) {
            this.setComponentValuesOnEditAndCopy();
        }
    }
}
