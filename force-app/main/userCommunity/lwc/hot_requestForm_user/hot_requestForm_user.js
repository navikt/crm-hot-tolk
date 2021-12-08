import { LightningElement, track, api } from 'lwc';
export default class Hot_requestForm_user extends LightningElement {
    @api isEditMode = false;
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

    personNumberErrorText = 'Personnummer må fylles ut.';
    @api
    validateFields() {
        this.personNumberErrorText = 'Personnummer må fylles ut.';
        let hasErrors = 0;
        this.template.querySelectorAll('c-input').forEach((element) => {
            if (element.validationHandler()) {
                hasErrors += 1;
            }
        });
        if (this.template.querySelectorAll('c-input')[1].validatePersonNumber()) {
            this.personNumberErrorText = 'Ikke gyldig personnummer.';
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
}
