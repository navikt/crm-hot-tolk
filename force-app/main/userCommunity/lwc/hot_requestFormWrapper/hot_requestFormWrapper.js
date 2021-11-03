import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import createAndUpdateWorkOrders from '@salesforce/apex/HOT_RequestHandler.createAndUpdateWorkOrders';
import createWorkOrders from '@salesforce/apex/HOT_CreateWorkOrderService.createWorkOrdersFromCommunity';
import checkDuplicates from '@salesforce/apex/HOT_DuplicateHandler.checkDuplicates';
import getPersonAccount from '@salesforce/apex/HOT_Utility.getPersonAccount';
import { getParametersFromURL } from 'c/hot_URIDecoder';

export default class Hot_requestFormWrapper extends NavigationMixin(LightningElement) {
    @track submitted = false; // if:false={submitted}
    @track recordId = null;
    @track spin = false;
    @track requestTypeChosen = false;
    @track fieldValues = {};

    @track personAccount = { Id: '', Name: '' };
    @wire(getPersonAccount)
    wiredGetPersonAccount(result) {
        if (result.data) {
            this.personAccount.Id = result.data.AccountId;
            this.personAccount.Name = result.data.Account.CRM_Person__r.CRM_FullName__c;
        }
    }

    @track requestTypeResult = {};
    handleRequestType(event) {
        this.requestTypeResult = event.detail;
        this.requestTypeChosen = true;
        this.fieldValues.Type__c = this.requestTypeResult.type;
        console.log(JSON.stringify(this.requestTypeResult));
        //this.fieldValues.EventType__c = this.requestTypeResult.eventType;
    }

    async handleSubmit(event) {
        console.log('handleSubmit');
        event.preventDefault();
        this.spin = true;
        this.setAccountLookupFieldsBasedOnRequestType();
        this.getFieldValuesFromSubForms();
        let hasErrors = this.handleValidation();
        //TODO: Should not validate before first attempt of submit
        //use attemptedSubmit with onblur functions. if we can get a map from element to validation rules, this will be nice.
        //TODO: Generalize validation and add tolk-skjema-input to all elements.
        // We can then fetch all elements with this class, reverse the list, and then have a map from element to validation rules.
        // this will ensure easy js code
        //example of map in validationRules.js: export function getValidationRules(element){ case element.name --> return list of validation rules}
        if (!hasErrors) {
            this.promptOverlap().then((overlapOk) => {
                if (overlapOk) {
                    this.submitForm();
                } else {
                    this.spin = false;
                }
            });
        } else {
            this.spin = false;
        }
    }
    setAccountLookupFieldsBasedOnRequestType() {
        this.fieldValues.Orderer__c = this.personAccount.Id;
        if (this.requestTypeResult.type === 'Me') {
            this.fieldValues.Account__c = this.personAccount.Id;
        }
    }

    getFieldValuesFromSubForms() {
        this.template.querySelectorAll('.subform').forEach((subForm) => {
            subForm.setFieldValues();
            this.setFieldValues(subForm.getFieldValues());
        });
    }
    setFieldValues(fields) {
        for (let k in fields) {
            this.fieldValues[k] = fields[k];
        }
    }

    handleValidation() {
        console.log('handleValidation');
        let hasErrors = false;
        this.template.querySelectorAll('.subform').forEach((subForm) => {
            hasErrors = hasErrors + subForm.validateFields();
        });
        return hasErrors;
    }

    async promptOverlap() {
        console.log('promptOverlap');
        let response = true;
        let timeInput = this.template.querySelector('c-hot_request-form_request').getTimeInput();
        if (!timeInput.isAdvancedTimes && this.fieldValues.Type__c === 'Me') {
            let duplicateRequests = await checkDuplicates({
                accountId: this.personAccount.Id,
                times: timeInput.times
            });
            if (duplicateRequests.length > 0) {
                let warningMessage = 'Du har allerede bestillinger i dette tidsrommet:';
                for (let request of duplicateRequests) {
                    warningMessage += '\nEmne: ' + request.Subject__c;
                    warningMessage += '\nPeriode: ' + request.SeriesPeriod__c;
                }
                response = confirm(warningMessage);
            }
        }
        return response;
    }

    submitForm() {
        console.log('submitForm()');
        try {
            this.template.querySelector('lightning-record-edit-form').submit(this.fieldValues);
        } catch (error) {
            throw error;
        }
    }
    handleError(error) {
        console.log(JSON.stringify(error));
        this.spin = false;
    }

    @track isEditMode = false;
    handleSuccess(event) {
        console.log('handle Success');
        this.spin = false;
        this.recordId = event.detail.id;

        this.hideFormAndShowSuccess();
        this.uploadFiles();
        this.createWorkOrders();

        window.scrollTo(0, 0);
    }

    hideFormAndShowSuccess() {
        this.template.querySelector('.submitted-true').classList.remove('hidden');
        this.template.querySelector('.h2-successMessage').focus();
        this.template.querySelector('.submitted-false').classList.add('hidden');
    }

    uploadFiles() {
        this.template.querySelector('c-hot_request-form_request').handleFileUpload(this.recordId);
    }

    createWorkOrders() {
        let timeInput = this.template.querySelector('c-hot_request-form_request').getTimeInput();
        if (timeInput.times !== {}) {
            console.log('timeInput.isAdvancedTimes: ' + timeInput.isAdvancedTimes);
            console.log(JSON.stringify(timeInput.times));
            if (timeInput.isAdvancedTimes) {
                try {
                    createWorkOrders({
                        requestId: this.recordId,
                        times: timeInput.times['0'],
                        recurringType: timeInput.repeatingOptionChosen,
                        recurringDays: timeInput.chosenDays,
                        recurringEndDate: new Date(timeInput.repeatingEndDate).getTime()
                    });
                } catch (error) {
                    console.log(JSON.stringify(error));
                }
            } else {
                createAndUpdateWorkOrders({ requestId: this.recordId, times: timeInput.times });
            }
        }
    }

    previousPage = 'home';
    connectedCallback() {
        console.log('connectedCallback');
        let parsed_params = getParametersFromURL();
        if (parsed_params != null) {
            if (parsed_params.fromList != null) {
                this.previousPage = 'mine-bestillinger';
            }

            if (parsed_params.fieldValues != null) {
                this.setFieldValuesFromURL(parsed_params);
            }
        }
    }
    handleEditModeRequestType(parsed_params) {
        this.isEditMode = parsed_params.edit != null;
        this.requestTypeChosen = parsed_params.edit != null || parsed_params.copy != null;
        if (this.requestTypeChosen) {
            this.requestTypeResult.requestForm = true;
            if (this.fieldValues.Type__c !== 'Me' && this.fieldValues.Type__c != null) {
                this.requestTypeResult.ordererForm = true;
                this.requestTypeResult.userForm = this.fieldValues.Type__c !== 'Company';
                this.requestTypeResult.companyForm = this.fieldValues.Type__c !== 'User';
            }
        }
    }

    handleUserCheckbox(event) {
        this.requestTypeResult.userForm = event.detail;
        console.log(this.requestTypeResult.userForm);
    }

    isGetAll = false;
    setFieldValuesFromURL(parsed_params) {
        this.fieldValues = JSON.parse(parsed_params.fieldValues);
        this.handleEditModeRequestType(parsed_params);

        this.isGetAll = this.fieldValues.Account__c === this.personAccount.Id ? true : false;

        delete this.fieldValues.Account__c;
        delete this.fieldValues.Company__c;
        delete this.fieldValues.StartTime__c;
        delete this.fieldValues.EndTime__c;

        if (parsed_params.copy != null) {
            delete this.fieldValues.Id;
        } else {
            this.recordId = this.fieldValues.Id;
            let requestIds = [];
            requestIds.push(this.fieldValues.Id);
            this.requestIds = requestIds;
        }

        /* if (this.fieldValues.Type__c === 'PublicEvent') {
            this.fieldValues.EventType__c = this.fieldValues.EventType__c === 'Annet' ? 'OtherEvent' : 'SportingEvent';
        }
    */
    }

    goToMyRequests() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                pageName: 'mine-bestillinger'
            }
        });
    }
    goToPreviousPage() {
        window.scrollTo(0, 0);
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                pageName: this.previousPage
            }
        });
    }
}
