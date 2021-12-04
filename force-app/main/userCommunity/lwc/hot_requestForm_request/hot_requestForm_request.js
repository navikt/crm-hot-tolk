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
        IsScreenInterpreter__c: false,
        UserPhone__c: '',
        UserPreferredInterpreter__c: '',
        AssignmentType__c: '',
        UserInterpretationMethods__c: []
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
            this.sameAddressRadioButtons[1].checked = true;
        }
        if (this.physicalOrDigitalFromWrapper.length > 0) {
            if (this.physicalOrDigitalFromWrapper[0].checked) {
                this.physicalOrDigitalRadiobuttons[0].checked = true;
                this.isAddressFields = true;
            } else {
                this.physicalOrDigitalRadiobuttons[1].checked = true;
                this.sendEndOfFormValue(true);
            }
        }
        if (this.sameAddressFromWrapper.length > 0) {
            if (this.sameAddressFromWrapper[0].checked) {
                this.sameLocation = true;
                this.sameAddressRadioButtons[0].checked = true;
            } else {
                this.sameLocation = false;
                this.sameAddressRadioButtons[1].checked = true;
            }
            this.sendEndOfFormValue(true);
        }
        this.isOptionalFields = this.optionalCheckboxFromWrapper;
        this.setAssignmentPicklistValue();
        this.setInterprationValues();
    }

    interpretationChoices = [
        { name: 'BTV', label: 'Bildetolkvakt' },
        { name: 'SK', label: 'Skrivetolking' },
        { name: 'TS', label: 'Tegnspråk' },
        { name: 'TSBS', label: 'Tegnspråk I Begrenset Synsfelt' },
        { name: 'TSS', label: 'Tegn Som Støtte Til Munnavlesning' },
        { name: 'TT', label: 'Taletolking' },
        { name: 'TTS', label: 'Taktilt Tegnspråk' }
    ];

    //TODO: See how it looks like when editing (also with existing files on request)
    //TODO: Remove the arrow on multiple picklist
    handleInterpretationPicklist(event) {
        this.fieldValues.UserInterpretationMethods__c = [];
        event.detail.forEach((element) => {
            this.fieldValues.UserInterpretationMethods__c.push(element.label);
        });
        this.sendInterpretationValues();
    }

    sendInterpretationValues() {
        const selectedEvent = new CustomEvent('interpretationpicklist', {
            detail: this.fieldValues.UserInterpretationMethods__c
        });
        this.dispatchEvent(selectedEvent);
    }

    @api interpretationPicklistInWrapper;
    setInterprationValues() {
        if (this.interpretationPicklistInWrapper === null || this.interpretationPicklistInWrapper === undefined) {
            return;
        }
        this.interpretationChoices.forEach((element) => {
            element.selected = false;
            if (this.interpretationPicklistInWrapper.includes(element.label)) {
                element.selected = true;
            }
        });
    }

    assignmentChoices = [
        { name: '', label: 'Velg et alternativ', selected: true },
        { name: 'Private', label: 'Dagligliv' },
        { name: 'Work', label: 'Arbeidsliv' },
        { name: 'Health Services', label: 'Helsetjenester' },
        { name: 'Education', label: 'Utdanning' },
        { name: 'Interpreter at Work', label: 'Tolk på arbeidsplass - TPA' },
        { name: 'Image Interpreter', label: 'Bildetolkvakt' }
    ];

    handleAssignmentPicklist(event) {
        this.fieldValues.AssignmentType__c = event.detail.name;
        this.sendAssignmentPicklist();
    }

    sendAssignmentPicklist() {
        const selectedEvent = new CustomEvent('assignmentpicklist', {
            detail: this.fieldValues.AssignmentType__c
        });
        this.dispatchEvent(selectedEvent);
    }

    @api assignmentPicklistInWrapper;
    setAssignmentPicklistValue() {
        if (this.assignmentPicklistInWrapper === undefined || this.assignmentPicklistInWrapper === null) {
            return;
        }
        this.assignmentChoices.forEach((element) => {
            element.selected = false;
            if (element.name === this.assignmentPicklistInWrapper) {
                element.selected = true;
            }
        });
    }

    @api
    setFieldValues() {
        this.template.querySelectorAll('c-input').forEach((element) => {
            this.fieldValues[element.name] = element.getValue();
        });
        if (this.isOptionalFields) {
            this.fieldValues.Description__c = this.template.querySelector('c-textarea').getValue();
        }
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
    isAddressFields = false;
    sameLocation = true;
    sameAddressRadioButtons = [
        { label: 'Ja', value: 'yes' },
        { label: 'Nei', value: 'no' }
    ];

    @api sameAddressFromWrapper = [];
    sendSameAddressRadioButtonValues(res) {
        const selectedEvent = new CustomEvent('sameaddressradiobuttons', {
            detail: res
        });
        this.dispatchEvent(selectedEvent);
    }

    handleSameAddressRadiobuttons(event) {
        let result = event.detail;
        this.sendEndOfFormValue(true);
        this.sendSameAddressRadioButtonValues(result);
        if (result[0].checked) {
            this.sameLocation = true;
        } else {
            this.sameLocation = false;
        }
    }

    sendEndOfFormValue(bool) {
        const selectedEvent = new CustomEvent('isendofform', {
            detail: bool
        });
        this.dispatchEvent(selectedEvent);
    }

    isOptionalFields = false;
    handleOptionalCheckbox(event) {
        this.isOptionalFields = event.detail;
        this.sendOptionalCheckbox();
    }

    @api optionalCheckboxFromWrapper = false;
    sendOptionalCheckbox() {
        const selectedEvent = new CustomEvent('optionalcheckbox', {
            detail: this.isOptionalFields
        });
        this.dispatchEvent(selectedEvent);
    }

    sendPhysicalOrDigital(res) {
        const selectedEvent = new CustomEvent('physicalordigital', {
            detail: res
        });
        this.dispatchEvent(selectedEvent);
    }

    physicalOrDigitalRadiobuttons = [
        { label: 'Fysisk oppmøte', value: 'Fysisk' },
        { label: 'Digitalt møte', value: 'Digitalt' }
    ];

    @api physicalOrDigitalFromWrapper = [];
    handlePhysicalOrDigital(event) {
        this.sameLocation = true;
        let result = event.detail;
        this.sendPhysicalOrDigital(result);
        if (result[0].checked) {
            this.fieldValues.IsScreenInterpreter__c = false;
            this.sendEndOfFormValue(false);
        } else {
            this.sendEndOfFormValue(true);
            this.fieldValues.IsScreenInterpreter__c = true;
        }
        if (this.fieldValues.IsScreenInterpreter__c) {
            this.fieldValues.MeetingStreet__c = '';
            this.fieldValues.MeetingPostalCity__c = '';
            this.fieldValues.MeetingPostalCode__c = '';
            this.fieldValues.InterpretationStreet__c = '';
            this.fieldValues.InterpretationPostalCode__c = '';
            this.fieldValues.InterpretationPostalCity__c = '';
        }
        this.isAddressFields = true;
    }

    advancedSection = false;
    handleAdvancedButtonClicked() {
        this.advancedSection = !this.advancedSection;
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
