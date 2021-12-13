import { LightningElement, track, api } from 'lwc';
export default class Hot_requestForm_user extends LightningElement {
    @api isEditMode = false;
    @api isCopyMode = false;
    @track fieldValues = {
        UserName__c: '',
        UserPersonNumber__c: ''
    };

    @api
    setFieldValues() {
        this.template.querySelectorAll('c-input').forEach((element) => {
            this.fieldValues[element.name] = element.getValue();
        });
    }

    personNumberErrorText = 'Ikke gyldig personnummer.';
    @api
    validateFields() {
        let hasErrors = 0;
        this.template.querySelectorAll('c-input').forEach((element) => {
            if (element.validationHandler()) {
                hasErrors += 1;
            }
        });
        if (this.template.querySelectorAll('c-input')[1].validatePersonNumber()) {
            hasErrors += 1;
        }
        return hasErrors;
    }

    @api
    getFieldValues() {
        return this.fieldValues;
    }

    isCopyOrEditMode = false;
    @api parentFieldValues;
    connectedCallback() {
        for (let field in this.parentFieldValues) {
            if (this.fieldValues[field] != null) {
                this.fieldValues[field] = this.parentFieldValues[field];
            }
        }
        if (this.isCopyMode || this.isEditMode) {
            this.isCopyOrEditMode = true;
        }
    }
}
