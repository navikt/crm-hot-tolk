import { LightningElement, track, api } from 'lwc';
import getPostalCity from '@salesforce/apex/HOT_RequestListController.getPostalCity';

export default class hot_requestForm_request_v2 extends LightningElement {
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
        UserPreferredInterpreter__c: '',
        AssignmentType__c: '',
        UserInterpretationMethod__c: '',
        Type__c: ''
    };
    isRequestTypeMe = false;
    @api isGetAll;
    @api requestIds;
    @api recordId;
    @api parentFieldValues;
    @api parentRequestComponentValues;
    @api isEditOrCopyMode = false;

    // Dont want to use this because focus will move to top on re-rendrering which happens on "Additional information"
    // renderedCallback() {
    //     this.template.querySelector('h2').focus();
    // }

    connectedCallback() {
        // This gives DOM(?) time to catch up and set focus correctly
        this.showDiv = true;
        setTimeout(() => this.template.querySelector('h2').focus());

        for (let field in this.parentFieldValues) {
            if (this.fieldValues[field] != null) {
                this.fieldValues[field] = this.parentFieldValues[field];
            }
        }
        for (let field in this.parentRequestComponentValues) {
            if (this.componentValues[field] != null) {
                this.componentValues[field] = JSON.parse(JSON.stringify(this.parentRequestComponentValues[field]));
            }
        }
        this.isRequestTypeMe = this.fieldValues.Type__c === 'Me';
        if (this.fieldValues.Type__c !== 'Company') {
            this.removeTPAFromAssignmentList();
        }
        if (this.isEditOrCopyMode) {
            this.setFieldAndElementSelected(
                this.componentValues.assignmentChoices,
                this.fieldValues.AssignmentType__c,
                'AssignmentType__c',
                'label'
            );
            this.setFieldAndElementSelected(
                this.componentValues.interpretationChoices,
                this.fieldValues.UserInterpretationMethod__c,
                'UserInterpretationMethod__c',
                'label'
            );
            this.setComponentValuesOnEditAndCopy();
        }
        this.fieldValues.IsScreenInterpreter__c = this.componentValues.physicalOrDigitalRadiobuttons[1].checked;
        this.sameLocation = this.componentValues.sameAddressRadioButtons[0].checked;
        if (this.sameLocation) {
            this.clearInterpretationFields();
        }
    }

    /**
     * Fetches the postal city based on the postal code.
     * @param {Event} event - Input event from the postal code field.
     * @param {string} postalField - Field name for the postal code.
     * @param {string} cityField - Field name for the postal city to update.
     */
    ariaPostalStatus = '.';

    handlePostalCity(event, postalField, cityField) {
        this.ariaPostalStatus = '';
        const postalCode = event.detail?.value || event.target?.value;
        this.fieldValues[postalField] = postalCode;

        if (!postalCode || postalCode.length !== 4) {
            this.fieldValues[cityField] = 'Feltet fylles automatisk';
            return;
        }

        this.fieldValues[cityField] = 'Henter poststed...';

        getPostalCity({ postalCode })
            .then((result) => {
                let message;
                if (result && result.length === 1) {
                    this.fieldValues[cityField] = result[0].Name;
                    message = result[0].Name;
                } else {
                    this.fieldValues[cityField] = 'Kunne ikke finne poststed';
                    message = 'Kunne ikke finne poststed';
                }
                setTimeout(() => {
                    this.ariaPostalStatus = message;
                }, 1000);
            })
            .catch((error) => {
                console.error(error);
                this.fieldValues[cityField] = 'Feil ved henting av poststed';
                setTimeout(() => {
                    this.ariaPostalStatus = 'Feil ved henting av poststed';
                }, 1000);
            });
    }

    handleMeetingPostalChange(event) {
        this.handlePostalCity(event, 'MeetingPostalCode__c', 'MeetingPostalCity__c');
    }

    handleInterpretationPostalChange(event) {
        this.handlePostalCity(event, 'InterpretationPostalCode__c', 'InterpretationPostalCity__c');
    }

    removeTPAFromAssignmentList() {
        let index = this.componentValues.assignmentChoices.findIndex((assignment) => {
            return assignment.name === 'Interpreter at Work';
        });
        if (index !== -1) {
            this.componentValues.assignmentChoices.splice(index, 1);
        }
    }

    setFieldAndElementSelected(arr, value, field, attributeToCheck) {
        arr.forEach((element) => {
            element.selected = false;
            if (attributeToCheck === 'label') {
                if (element.label === value) {
                    this.fieldValues[field] = element.name;
                    element.selected = true;
                }
            } else {
                if (value === '') {
                    this.fieldValues[field] = null;
                } else if (element.name === value) {
                    this.fieldValues[field] = element.name;
                    element.selected = true;
                }
            }
        });
    }

    setComponentValuesOnEditAndCopy() {
        this.componentValues.physicalOrDigitalRadiobuttons[0].checked = !this.fieldValues.IsScreenInterpreter__c;
        this.componentValues.physicalOrDigitalRadiobuttons[1].checked = this.fieldValues.IsScreenInterpreter__c;
        this.componentValues.sameAddressRadioButtons[1].checked =
            this.fieldValues.InterpretationStreet__c !== this.fieldValues.MeetingStreet__c;
        this.componentValues.sameAddressRadioButtons[0].checked =
            !this.componentValues.sameAddressRadioButtons[1].checked;
        this.componentValues.isOptionalFields =
            this.fieldValues.UserInterpretationMethod__c !== '' ||
            this.fieldValues.UserPreferredInterpreter__c !== '' ||
            this.fieldValues.AssignmentType__c !== '';
    }

    @track componentValues = {
        physicalOrDigitalRadiobuttons: [
            { label: 'Fysisk oppmøte', value: 'Fysisk', checked: true },
            { label: 'Digitalt møte', value: 'Digitalt' }
        ],
        sameAddressRadioButtons: [
            { label: 'Ja', value: 'yes', checked: true },
            { label: 'Nei', value: 'no' }
        ],
        assignmentChoices: [
            { name: '', label: 'Velg et alternativ', selected: true },
            { name: 'Private', label: 'Dagligliv' },
            { name: 'Work', label: 'Arbeidsliv' },
            { name: 'Health Services', label: 'Helsetjenester' },
            { name: 'Education', label: 'Utdanning' },
            { name: 'Interpreter at Work', label: 'Tolk på arbeidsplass - TPA' }
        ],
        interpretationChoices: [
            { name: '', label: 'Velg et alternativ', selected: true },
            { name: 'SK', label: 'Skrivetolking' },
            { name: 'TS', label: 'Tegnspråk' },
            { name: 'TSBS', label: 'Tegnspråk i begrenset synsfelt' },
            { name: 'TSS', label: 'Tegn som støtte til munnavlesning' },
            { name: 'TT', label: 'Taletolking' },
            { name: 'TTS', label: 'Taktilt tegnspråk' }
        ],
        isOptionalFields: false
    };

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

    @api getComponentValues() {
        return this.componentValues;
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
        return this.template.querySelector('c-hot_recurring-time-input_v2').getTimeInput();
    }

    @api
    validateFields() {
        let hasErrors = false;

        this.template.querySelectorAll('c-input').forEach((element) => {
            if (element.validationHandler()) {
                hasErrors += 1;
            }

            // Postal code validation
            if (
                element.name === 'MeetingPostalCode__c' ||
                element.name === 'InterpretationPostalCode__c'
            ) {
                const postalCode = element.getValue() || '';
                const cityField = element.name === 'MeetingPostalCode__c'
                    ? this.fieldValues.MeetingPostalCity__c
                    : this.fieldValues.InterpretationPostalCity__c;

                if (!postalCode) {
                    element.sendErrorMessage('Postnummer må fylles ut.');
                    hasErrors += 1;
                } else if (postalCode.length !== 4) {
                    element.sendErrorMessage('Postnummer må være 4 siffer.');
                    hasErrors += 1;
                } else if (
                    cityField === 'Kunne ikke finne poststed' ||
                    cityField === 'Feil ved henting av poststed'
                ) {
                    element.sendErrorMessage('Vennligst tast inn gyldig postnummer.');
                    hasErrors += 1;
                } else {
                    element.sendErrorMessage(''); 
                }
            }
        });

        hasErrors += this.validateCheckbox();
        hasErrors += this.template.querySelector('c-hot_recurring-time-input_v2').validateFields();

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

    sameLocation = true;
    handleSameAddressRadiobuttons(event) {
        this.componentValues.sameAddressRadioButtons = event.detail;
        if (event.detail[0].checked) {
            this.sameLocation = true;
            this.clearInterpretationFields();
        } else {
            this.sameLocation = false;
        }
    }

    handleOptionalCheckbox(event) {
        this.componentValues.isOptionalFields = event.detail;
    }

    handlePhysicalOrDigital(event) {
        this.componentValues.physicalOrDigitalRadiobuttons = event.detail;
        this.fieldValues.IsScreenInterpreter__c = this.componentValues.physicalOrDigitalRadiobuttons[1].checked;
        this.clearPhysicalAddressFields();
    }

    clearPhysicalAddressFields() {
        if (this.fieldValues.IsScreenInterpreter__c) {
            this.fieldValues.MeetingStreet__c = '';
            this.fieldValues.MeetingPostalCity__c = '';
            this.fieldValues.MeetingPostalCode__c = '';
            this.fieldValues.InterpretationStreet__c = '';
            this.fieldValues.InterpretationPostalCode__c = '';
            this.fieldValues.InterpretationPostalCity__c = '';
            this.componentValues.sameAddressRadioButtons[0].checked = true;
            this.componentValues.sameAddressRadioButtons[1].checked = false;
            this.sameLocation = true;
        }
    }

    clearInterpretationFields() {
        this.fieldValues.InterpretationStreet__c = '';
        this.fieldValues.InterpretationPostalCode__c = '';
        this.fieldValues.InterpretationPostalCity__c = '';
    }

    handleInterpretationPicklist(event) {
        this.setFieldAndElementSelected(
            this.componentValues.interpretationChoices,
            event.detail.name,
            'UserInterpretationMethod__c'
        );
    }

    handleAssignmentPicklist(event) {
        this.setFieldAndElementSelected(this.componentValues.assignmentChoices, event.detail.name, 'AssignmentType__c');
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

    @api deleteMarkedFiles() {
        let ele = this.template.querySelector('c-record-files-with-sharing');
        if (ele !== null) {
            ele.deleteMarkedFiles();
        }
    }

    onUploadComplete() {
        if (this.template.querySelector('c-record-files-with-sharing') !== null) {
            this.template.querySelector('c-record-files-with-sharing').refreshContentDocuments();
        }
    }
}
