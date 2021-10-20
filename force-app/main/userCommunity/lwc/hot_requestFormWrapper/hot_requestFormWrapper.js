import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import createAndUpdateWorkOrders from '@salesforce/apex/HOT_RequestHandler.createAndUpdateWorkOrders';
import createWorkOrders from '@salesforce/apex/HOT_CreateWorkOrderService.createWorkOrdersFromCommunity';
import checkDuplicates from '@salesforce/apex/HOT_DuplicateHandler.checkDuplicates';
import getPersonAccount from '@salesforce/apex/HOT_Utility.getPersonAccount';

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

    @track requestTypeResult;
    handleRequestType(event) {
        console.log(JSON.stringify(event.detail));
        this.requestTypeResult = event.detail;
        this.requestTypeChosen = true;
        this.fieldValues.Type__c = this.requestTypeResult.type;
        this.fieldValues.EventType__c = this.requestTypeResult.eventType;
    }

    handleSubmit(event) {
        console.log('handleSubmit');
        event.preventDefault();
        this.spin = true;
        let isValid = false;
        this.setAccountLookupFieldsBasedOnRequestType();
        this.getFieldValuesFromSubForms();
        isValid = this.handleValidation();
        if (isValid) {
            // && this.promptOverlap()) {
            this.submitForm();
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
            this.setFieldValues(subForm.fieldValues);
        });
    }
    setFieldValues(fields) {
        for (let k in fields) {
            this.fieldValues[k] = fields[k];
        }
    }

    handleValidation() {
        console.log('handleValidation');
        this.template.querySelectorAll('.subform').forEach((subForm) => {
            subForm.validateFields();
        });
    }

    async promptOverlap() {
        if (!this.isAdvancedTimes && this.fieldValues.Type__c === 'Me') {
            let accountId = this.personAccount.Id;
            let times = this.timesListToObject(this.times);
            duplicateRequests = [];
            let duplicateRequests = await checkDuplicates({
                accountId: accountId,
                times: times
            });
            if (duplicateRequests.length > 0) {
                let warningMessage = 'Du har allerede bestillinger i dette tidsrommet:';
                for (let request of duplicateRequests) {
                    warningMessage += '\nEmne: ' + request.Subject__c;
                    warningMessage += '\nPeriode: ' + request.SeriesPeriod__c;
                }
                return confirm(warningMessage);
            }
        }
        return true;
    }

    submitForm() {
        this.template.querySelector('lightning-record-edit-form').submit(this.fieldValues);
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
            if (timeInput.isAdvancedTimes) {
                createWorkOrders({
                    requestId: this.recordId,
                    times: timeInput.times['0'],
                    recurringType: timeInput.repeatingOptionChosen,
                    recurringDays: timeInput.chosenDays,
                    recurringEndDate: new Date(timeInput.repeatingEndDate).getTime()
                });
            } else {
                createAndUpdateWorkOrders({ requestId: this.recordId, times: timeInput.times });
            }
        }
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
                this.requestTypeChosen = parsed_params.edit != null || parsed_params.copy != null;
                if (this.requestTypeChosen) {
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
