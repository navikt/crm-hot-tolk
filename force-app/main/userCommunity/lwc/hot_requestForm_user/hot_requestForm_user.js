import { LightningElement, track, api } from 'lwc';
import { personNumberValidationRules } from './hot_validationRules';
import { validate, require } from 'c/validationController';

export default class Hot_requestForm_user extends LightningElement {
    @api fieldValues = {
        UserName__c: '',
        UserPersonNumber__c: ''
    };

    @api
    setFieldValues() {
        this.template.querySelectorAll('.tolk-skjema-input').forEach((element) => {
            this.fieldValues[element.name] = element.value;
        });
    }

    @api
    validateFields() {
        let hasErrors = validate(this.template.querySelector('[data-id="personnumber"]'), personNumberValidationRules);
        this.template.querySelectorAll('.tolk-skjema-input').forEach((element) => {
            if (element.required) {
                hasErrors = hasErrors * validate(element, [require]);
            }
        });
    }
}
