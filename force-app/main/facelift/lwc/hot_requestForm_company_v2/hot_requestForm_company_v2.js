import { LightningElement, track, api } from 'lwc';
import getOrganizationInfo from '@salesforce/apex/HOT_RequestListController.getOrganizationInfo';
export default class hot_requestForm_company_v2 extends LightningElement {
    @api isEditOrCopyMode = false;
    @track fieldValues = {
        OrganizationNumber__c: '',
        OrganizationName__c: '',
        InvoiceReference__c: '',
        IsOtherEconomicProvicer__c: false,
        AdditionalInvoiceText__c: '',
        UserName__c: '' // Get UserName from Wrapper on edit/copy. Deleted in getFieldValues() and handled in requestForm_user afterwards.
    };

    @api parentCompanyComponentValues;
    @track componentValues = {
        choices: [
            { name: 'Placeholder', label: 'Velg et alternativ', selected: true },
            { name: 'NAV', label: 'NAV betaler' },
            { name: 'Virksomhet', label: 'Virksomhet betaler' }
        ],
        checkboxValue: true
    };
    organizationNumberSearch;

    handleOrgNumberInputChange(event) {
        this.organizationNumberSearch = event.detail;

        if (this.organizationNumberSearch.length == 9) {
            this.fieldValues.OrganizationName__c = 'Henter organisasjon...';

            getOrganizationInfo({
                organizationNumber: this.organizationNumberSearch
            })
                .then((result) => {
                    if (result.length === 1) {
                        this.fieldValues.OrganizationName__c = result[0].Name;
                    } else {
                        this.fieldValues.OrganizationName__c = 'Kunne ikke finne organisasjon';
                    }
                })
                .catch((error) => {
                    console.error('Feil ved henting av organisasjon:', error);
                    this.fieldValues.OrganizationName__c = 'Feil ved henting av organisasjon';
                });
        } else {
            this.fieldValues.OrganizationName__c = '';
        }
    }

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
        if (this.validateOrganizationName()) {
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

    @api parentFieldValues;
    connectedCallback() {
        this.showDiv = true;
        setTimeout(() => this.template.querySelector('h2').focus());

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
    validateOrganizationName() {
        let hasErrors = false;
        this.template.querySelectorAll('[data-id="organizationName"]').forEach((element) => {
            if (element.value === '' || element.value === 'Kunne ikke finne organisasjon') {
                hasErrors = true;
                this.showErrorOrganizationNumber();
            }
        });
        return hasErrors;
    }
    showErrorOrganizationNumber() {
        this.template.querySelectorAll('[data-id="organizationNumber"]').forEach((element) => {
            element.sendErrorMessage('Fyll inn en gyldig organisasjonsnummer');
        });
    }
}
