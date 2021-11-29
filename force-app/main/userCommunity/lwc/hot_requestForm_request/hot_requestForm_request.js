import { LightningElement, track, api } from 'lwc';

export default class Hot_requestForm_request extends LightningElement {
    @track fieldValues = {
        Subject__c: '',
        MeetingStreet__c: '',
        MeetingPostalCity__c: '',
        MeetingPostalCode__c: '',
        InterpretationStreet__c: '',
        InterpretationPostalCode__c: '',
        InterpretationPostalCity__c: '',
        Description__c: '',
        IsFileConsent__c: false,
        Source__c: 'Community',
        IsOrdererWantStatusUpdateOnSMS__c: true,
        IsScreenInterpreter__c: false
    };
    @api isRequestTypeMe;
    @api isGetAll;
    @api requestIds;
    @api recordId;
    @api parentFieldValues;
    connectedCallback() {
        for (let field in this.parentFieldValues) {
            if (this.fieldValues[field] != null) {
                this.fieldValues[field] = this.parentFieldValues[field];
            }
        }
        this.sameLocation = this.fieldValues.MeetingStreet__c === this.fieldValues.InterpretationStreet__c;
        if (!this.sameLocation) {
            this.radiobuttonOptions[1].checked = true;
        }
    }

    @api
    setFieldValues() {
        this.template.querySelectorAll('c-input').forEach((element) => {
            this.fieldValues[element.name] = element.getValue();
        });
        this.fieldValues.Description__c = this.template.querySelector('c-textarea').getValue();
        this.setDependentFields();
    }

    @api
    getFieldValues() {
        return this.fieldValues;
    }

    setDependentFields() {
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
        let hasErrors = false;
        this.template.querySelectorAll('c-input').forEach((element) => {
            if (element.validationHandler()) {
                hasErrors += 1;
            }
        });
        hasErrors += this.validateCheckbox();
        hasErrors += this.template.querySelector('c-hot_recurring-time-input').validateFields();
        return hasErrors;
    }

    validateCheckbox() {
        if (this.hasFiles) {
            return this.template.querySelector('c-upload-files').validateCheckbox();
        }
        return false;
    }

    getFileConsent(event) {
        this.fieldValues.IsFileConsent__c = event.detail;
    }

    @track sameLocation = true;
    radiobuttonOptions = [
        { label: 'Ja', value: 'yes', checked: true },
        { label: 'Nei', value: 'no' }
    ];

    radiobuttonsToggled() {
        this.sameLocation = !this.sameLocation;
    }

    handleDigitalCheckbox(event) {
        this.fieldValues.IsScreenInterpreter__c = event.detail;
    }

    handleSMSCheckbox(event) {
        this.fieldValues.IsOrdererWantStatusUpdateOnSMS__c = event.detail;
    }

    uploadFilesDropHandler(event) {
        event.preventDefault();
        this.template.querySelector('c-upload-files').dropHandler(event);
    }

    dragOverHandler(event) {
        event.preventDefault();
    }
}
