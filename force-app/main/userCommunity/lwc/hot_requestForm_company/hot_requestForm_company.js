import { LightningElement, track, api } from 'lwc';

export default class Hot_requestForm_company extends LightningElement {
    @api fieldValues = {
        OrganizationNumber__c: '',
        InvoiceReference__c: '',
        AdditionalInvoiceText__c: ''
    };

    checkOrganizationNumber(event) {
        //Return if wrong format? ExpReg
    }

    @api
    setFieldValues() {
        this.template.querySelectorAll('.tolk-skjema-input').forEach((element) => {
            this.fieldValues[element.name] = element.value;
        });
    }

    @api
    validateFields() {}
}
