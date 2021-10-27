import { LightningElement, track, api } from 'lwc';
import { validate, require } from 'c/validationController';

export default class Hot_requestForm_request extends LightningElement {
    @track fieldValues2 = {
        Subject__c: '',
        StartTime__c: '',
        EndTime__c: '',
        MeetingStreet__c: '',
        MeetingPostalCity__c: '',
        MeetingPostalCode__c: '',
        InterpretationStreet__c: '',
        InterpretationPostalCode__c: '',
        InterpretationPostalCity__c: '',
        Description__C: '',
        IsFileConsent__c: false,
        Source__c: 'Community'
    };

    get fieldValues() {
        return this.fieldValues2;
    }

    @api
    editMode(parentFieldValues) {
        console.log('editMode');
        for (let field in parentFieldValues) {
            if (this.fieldValues2[field] != null) {
                this.fieldValues2[field] = parentFieldValues[field];
            }
        }
        console.log(JSON.stringify(this.fieldValues2));
    }

    @api
    setFieldValues() {
        this.template.querySelectorAll('.tolk-skjema-input').forEach((element) => {
            this.fieldValues[element.name] = element.value;
        });
        this.setDependentFields();
    }
    @api
    getFieldValues() {
        return this.fieldValues;
    }

    setDependentFields() {
        this.fieldValues.IsFileConsent__c = this.fileConsent;
        if (this.sameLocation) {
            this.fieldValues.InterpretationStreet__c = this.fieldValues.MeetingStreet__c;
            this.fieldValues.InterpretationPostalCode__c = this.fieldValues.MeetingPostalCode__c;
            this.fieldValues.InterpretationPostalCity__c = this.fieldValues.MeetingPostalCity__c;
        }
    }

    @api
    getTimeInput() {
        return this.template.querySelector('c-hot_recurring-time-input').getTimeInput();
    }
    @api
    handleFileUpload(recordId) {
        if (this.hasFiles) {
            this.template.querySelector('c-upload-files').handleFileUpload(recordId);
        }
    }
    hasFiles = false;
    checkFileDataLength(event) {
        this.hasFiles = event.detail > 0;
    }

    attemptedSubmit = false;
    @api
    validateFields() {
        this.attemptedSubmit = true;
        let hasErrors = false;
        this.template.querySelectorAll('.tolk-skjema-input').forEach((element) => {
            if (element.required) {
                hasErrors = hasErrors * validate(element, [require]);
            }
        });
        hasErrors = hasErrors * this.validateCheckbox();
        hasErrors = hasErrors * this.template.querySelector('c-hot_recurring-time-input').validateFields();
        return hasErrors;
    }
    validateCheckbox() {
        if (this.hasFiles) {
            return this.template.querySelector('c-upload-files').validateCheckbox();
        }
        return false;
    }
    fileConsent = false;
    getFileConsent(event) {
        this.fileConsent = event.detail;
    }
    checkPostalCode(event) {
        //check postal code ExpReg
    }

    @track sameLocation = true;
    value = 'yes';
    get options() {
        return [
            { label: 'Ja', value: 'yes' },
            { label: 'Nei', value: 'no' }
        ];
    }
    toggled() {
        this.sameLocation = !this.sameLocation;
    }
}
