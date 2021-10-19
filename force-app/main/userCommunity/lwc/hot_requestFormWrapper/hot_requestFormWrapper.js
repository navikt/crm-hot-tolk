import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import getRequestList from '@salesforce/apex/HOT_RequestListContoller.getRequestList';
import getPersonAccount from '@salesforce/apex/HOT_Utility.getPersonAccount';
import getOrdererDetails from '@salesforce/apex/HOT_Utility.getOrdererDetails';
import createAndUpdateWorkOrders from '@salesforce/apex/HOT_RequestHandler.createAndUpdateWorkOrders';
import createWorkOrders from '@salesforce/apex/HOT_CreateWorkOrderService.createWorkOrdersFromCommunity';
import checkDuplicates from '@salesforce/apex/HOT_DuplicateHandler.checkDuplicates';
import { validate } from 'c/validationController';
import {
    recurringTypeValidations,
    recurringDaysValidations,
    recurringEndDateValidations
} from './hot_createRequestForm_validationRules';

export default class Hot_requestFormWrapper extends NavigationMixin(LightningElement) {
    @track submitted = false; // if:false={submitted}
    @track recordId = null;
    @track allRequests;
    @track requests;
    @track error;
    wiredRequestsResult;

    @wire(getRequestList)
    wiredRequest(result) {
        this.wiredRequestsResult = result;
        if (result.data) {
            this.allRequests = result.data;
            this.filterRequests();
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            this.requests = undefined;
        }
    }
    filterRequests() {
        let tempRequests = [];
        for (let i = 0; i < this.allRequests.length; i++) {
            if (
                this.allRequests[i].ExternalRequestStatus__c !== 'Avlyst' &&
                this.allRequests[i].ExternalRequestStatus__c !== 'Dekket' &&
                this.allRequests[i].ExternalRequestStatus__c !== 'Udekket'
            ) {
                tempRequests.push(this.allRequests[i]);
            }
        }
        this.requests = tempRequests;
    }

    @track requestTypeResult;
    @track showNextButton = true;
    handleRequestType(event) {
        console.log(JSON.stringify(event.detail));
        this.requestTypeResult = event.detail;
        this.showNextButton = false;
    }

    @track isPersonNumberValid = true;
    checkPersonNumber() {
        let inputComponent = this.template.querySelector('.skjema').querySelector('.personNumber');
        this.fieldValues.UserPersonNumber__c = inputComponent.value;
        let regExp = RegExp('[0-7][0-9][0-1][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]');
        this.isPersonNumberValid = regExp.test(inputComponent.value);
    }
    reportValidityPersonNumberField() {
        let inputComponent = this.template.querySelector('.skjema').querySelector('.personNumber');
        if (!this.isPersonNumberValid) {
            inputComponent.setCustomValidity('Fødselsnummeret er ikke gyldig');
            inputComponent.focus();
        } else {
            inputComponent.setCustomValidity('');
        }
        inputComponent.reportValidity();
    }

    @track spin = false;

    validateCheckbox() {
        this.template.querySelector('c-upload-files').validateCheckbox();
    }

    checkboxValue = false;
    getCheckboxValue(event) {
        this.checkboxValue = event.detail;
    }

    handleValidation() {
        let checkboxValid = true;
        if (this.hasFiles) {
            this.validateCheckbox();
            checkboxValid = this.checkboxValue;
        }
        let datetimeValid = this.handleDatetimeValidation().length === 0;
        let advancedValid = true;

        if (this.isAdvancedTimes) {
            advancedValid = this.handleAdvancedTimeValidations();
        }
        return datetimeValid && this.handlePersonNumberValidation() && advancedValid && checkboxValid;
    }

    handlePersonNumberValidation() {
        if (!this.isPersonNumberValid) {
            this.reportValidityPersonNumberField();
        }
        return this.isPersonNumberValid;
    }

    async handleSubmit(event) {
        this.spin = true;
        event.preventDefault();
        const fields = event.detail.fields;

        if (fields) {
            this.setFieldValues(fields);
            let isValid = this.handleValidation();
            if (isValid) {
                if (!this.isAdvancedTimes) {
                    let accountId = this.personAccount.Id;
                    let times = this.timesListToObject(this.times);
                    let duplicateRequests = [];
                    if (this.fieldValues.Type__c === 'Me') {
                        duplicateRequests = await checkDuplicates({
                            accountId: accountId,
                            times: times
                        });
                    }
                    if (duplicateRequests.length === 0) {
                        this.submit();
                    } else {
                        let warningMessage = 'Du har allerede bestillinger i dette tidsrommet:';
                        for (let request of duplicateRequests) {
                            warningMessage += '\nEmne: ' + request.Subject__c;
                            warningMessage += '\nPeriode: ' + request.SeriesPeriod__c;
                        }
                        if (confirm(warningMessage)) {
                            this.submit();
                        } else {
                            this.spin = false;
                        }
                    }
                } else {
                    this.submit();
                }
            } else {
                this.spin = false;
            }
        }
    }
    submit() {
        this.template.querySelector('.skjema').querySelector('lightning-record-edit-form').submit(this.fieldValues);
    }

    setFieldValues(fields) {
        this.fieldValues.IsFileConsent__c = this.checkboxValue;
        this.fieldValues.OrdererEmail__c = fields.OrdererEmail__c;
        this.fieldValues.OrdererPhone__c = fields.OrdererPhone__c;
        this.fieldValues.Orderer__c = this.personAccount.Id;
        for (const k in fields) {
            this.fieldValues[k] = fields[k];
        }
        if (this.sameLocation) {
            this.fieldValues.InterpretationStreet__c = fields.MeetingStreet__c;
            this.fieldValues.InterpretationPostalCode__c = fields.MeetingPostalCode__c;
            this.fieldValues.InterpretationPostalCity__c = fields.MeetingPostalCity__c;
        }
    }

    throwInputValidationError(element, errorText) {
        element.setCustomValidity(errorText);
        if (errorText !== '') {
            element.focus();
        }
        element.reportValidity();
    }

    handleError() {
        this.spin = false;
    }

    @track isEditMode = false;
    handleSuccess(event) {
        this.spin = false;
        let x = this.template.querySelector('.submitted-true');
        x.classList.remove('hidden');
        this.template.querySelector('.h2-successMessage').focus();
        x = this.template.querySelector('.submitted-false');
        x.classList.add('hidden');
        this.recordId = event.detail.id;
        let requestId = event.detail.id;
        this.handleFileUpload();
        let times = this.timesListToObject(this.times);
        if (times !== {}) {
            if (this.isAdvancedTimes) {
                //String requestId, Map<String, Long> times, String recurringType, List<String> recurringDays, Long recurringEndDate
                let time = times['0'];
                let recurringType = this.repeatingOptionChosen;
                let recurringDays = this.chosenDays;
                let recurringEndDate = new Date(this.repeatingEndDate).getTime();
                createWorkOrders({
                    requestId,
                    times: time,
                    recurringType,
                    recurringDays,
                    recurringEndDate
                });
            } else {
                createAndUpdateWorkOrders({ requestId, times });
            }
        }

        window.scrollTo(0, 0);
    }

    handleFileUpload() {
        if (this.hasFiles) {
            this.template.querySelector('c-upload-files').handleFileUpload(this.recordId);
        }
    }

    hasFiles = false;
    checkFileDataLength(event) {
        this.hasFiles = event.detail > 0;
    }

    previousPage = 'home';
    isGetAll = false;
    connectedCallback() {
        window.scrollTo(0, 0);
        let testURL = window.location.href;
        let params = testURL.split('?')[1];

        function parse_query_string(query) {
            let vars = query.split('&');
            let query_string = {};
            for (let i = 0; i < vars.length; i++) {
                let pair = vars[i].split('=');
                let key = decodeURIComponent(pair[0]);
                let value = decodeURIComponent(pair[1]);
                // If first entry with this name
                if (typeof query_string[key] === 'undefined') {
                    query_string[key] = decodeURIComponent(value);
                    // If second entry with this name
                } else if (typeof query_string[key] === 'string') {
                    let arr = [query_string[key], decodeURIComponent(value)];
                    query_string[key] = arr;
                    // If third or later entry with this name
                } else {
                    query_string[key].push(decodeURIComponent(value));
                }
            }
            return query_string;
        }

        if (params !== undefined) {
            let parsed_params = parse_query_string(params);
            if (parsed_params.fromList != null) {
                this.previousPage = 'mine-bestillinger';
            }

            if (parsed_params.fieldValues != null) {
                this.fieldValues = JSON.parse(parsed_params.fieldValues);
                this.isGetAll = this.fieldValues.Account__c === this.personAccount.Id ? true : false;

                delete this.fieldValues.Account__c;
                delete this.fieldValues.Company__c;
                delete this.fieldValues.StartTime__c;
                delete this.fieldValues.EndTime__c;

                this.sameLocation = this.fieldValues.MeetingStreet__c === this.fieldValues.InterpretationStreet__c;
                if (!this.sameLocation) {
                    this.value = 'no';
                }
                this.isEditMode = parsed_params.edit != null;
                this.showNextButton = !(parsed_params.edit != null || parsed_params.copy != null);
                if (!this.showNextButton) {
                    this.requestForm = true;
                    if (this.fieldValues.Type__c !== 'Me' && this.fieldValues.Type__c != null) {
                        this.ordererForm = true;
                        this.userForm = this.fieldValues.Type__c !== 'PublicEvent';
                        this.companyForm = this.fieldValues.Type__c !== 'User';
                    }
                }
                if (!!parsed_params.copy) {
                    delete this.fieldValues.Id;
                } else {
                    this.recordId = this.fieldValues.Id;
                    let requestIds = [];
                    requestIds.push(this.fieldValues.Id);
                    this.requestIds = requestIds;
                    refreshApex(this.wiredTimesValue);
                }

                if (this.fieldValues.Type__c === 'PublicEvent') {
                    this.fieldValues.EventType__c =
                        this.fieldValues.EventType__c === 'Annet' ? 'OtherEvent' : 'SportingEvent';
                }
            }
        }
    }

    goToMyRequests() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                pageName: 'mine-bestillinger'
            }
        });
    }
    goToPrevousPage() {
        window.scrollTo(0, 0);
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                pageName: this.previousPage
            }
        });
    }
}
