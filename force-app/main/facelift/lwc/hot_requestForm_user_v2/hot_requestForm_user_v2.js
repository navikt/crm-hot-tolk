import { LightningElement, track, api } from 'lwc';
export default class hot_requestForm_user_v2 extends LightningElement {
    @api isEditOrCopyMode = false;
    @track fieldValues = {
        UserName__c: '',
        UserPersonNumber__c: '',
        UserPhone__c: ''
    };

    isBirthdate = true;
    birthdateAndPhoneRadiobuttons = [
        { label: 'Tolkebrukers fødselsnummer', value: 'birthdate', checked: true },
        { label: 'Tolkebrukers telefonnummer', value: 'phone' }
    ];

    handleBirthdateOrPhone(event) {
        if (this.birthdateAndPhoneRadiobuttons !== event.detail) {
            this.resetRadiobuttonFieldValues();
        }
        this.birthdateAndPhoneRadiobuttons = event.detail;
        this.isBirthdate = this.birthdateAndPhoneRadiobuttons[0].checked;
    }

    resetRadiobuttonFieldValues() {
        this.fieldValues.UserPersonNumber__c = '';
        this.fieldValues.UserPhone__c = '';
    }

    setRadiobuttonsOnConnected() {
        this.birthdateAndPhoneRadiobuttons[1].checked = this.fieldValues.UserPhone__c !== '';
        this.birthdateAndPhoneRadiobuttons[0].checked = !this.birthdateAndPhoneRadiobuttons[1].checked;
        this.isBirthdate = this.birthdateAndPhoneRadiobuttons[0].checked;
        if (this.isEditOrCopyMode) {
            this.birthdateAndPhoneRadiobuttons[0].disabled = true;
            this.birthdateAndPhoneRadiobuttons[1].disabled = true;
        }
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
        this.template.querySelectorAll('c-input').forEach((element) => {
            if (element.validationHandler()) {
                hasErrors += 1;
            }
        });

        hasErrors += this.isBirthdate
            ? this.template.querySelectorAll('c-input')[1].validatePersonNumber()
            : this.template
                  .querySelectorAll('c-input')[1]
                  .validatePhoneLength('Telefonnummer må være 8 siffer langt (ingen landskode).');
        return hasErrors;
    }

    @api
    getFieldValues() {
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
        this.setRadiobuttonsOnConnected();
    }
}
