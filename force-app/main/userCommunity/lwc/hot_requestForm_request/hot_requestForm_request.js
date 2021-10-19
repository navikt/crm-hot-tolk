import { LightningElement, track, api } from 'lwc';
import { validate, require } from 'c/validationController';

export default class Hot_requestForm_request extends LightningElement {
    @api fieldValues = {
        Subject__c: '',
        StartTime__c: '',
        EndTime__c: '',
        MeetingStreet__c: '',
        MeetingPostalCity__c: '',
        MeetingPostalCode__c: '',
        Description__C: '',
        IsFileConsent__c: false,
        Source__c: 'Community'
    };
    @api
    setFieldValues() {
        this.template.querySelectorAll('.tolk-skjema-input').forEach((element) => {
            this.fieldValues[element.name] = element.value;
        });
        this.setDependentFields();
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

    @api
    validateFields() {
        this.template.querySelectorAll('.tolk-skjema-input').forEach((element) => {
            if (element.required) {
                validate(element, [require]);
            }
        });
        this.validateCheckbox();
    }
    validateCheckbox() {
        if (this.hasFiles) {
            this.template.querySelector('c-upload-files').validateCheckbox();
        }
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
