import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import createAndUpdateWorkOrders from '@salesforce/apex/HOT_RequestHandler.createAndUpdateWorkOrders';
import isErrorOnRequestCreate from '@salesforce/apex/HOT_RequestHandler.isErrorOnRequestCreate';
import getRequestStatus from '@salesforce/apex/HOT_RequestListController.getRequestStatus';
import createWorkOrders from '@salesforce/apex/HOT_CreateWorkOrderService.createWorkOrdersFromCommunity';
import checkDuplicates from '@salesforce/apex/HOT_DuplicateHandler.checkDuplicates';
import getPersonAccount from '@salesforce/apex/HOT_Utility.getPersonAccount';
import { getParametersFromURL } from 'c/hot_URIDecoder';

export default class hot_requestFormWrapper_v2 extends NavigationMixin(LightningElement) {
    @track submitted = false; // if:false={submitted}
    @track recordId = null;
    @track spin = false;
    @track requestTypeChosen = false;
    @track fieldValues = {};
    @track componentValues = {};
    @track personAccount = { Id: '', Name: '' };
    @wire(getPersonAccount)
    wiredGetPersonAccount(result) {
        if (result.data) {
            this.personAccount.Id = result.data.AccountId;
            this.personAccount.Name = result.data.Account.CRM_Person__r.CRM_FullName__c;
        }
    }

    breadcrumbs = [
        {
            label: 'Tolketjenesten',
            href: ''
        },
        {
            label: 'Ny bestilling',
            href: 'ny-bestilling'
        }
    ];

    @track requestTypeResult = {};
    handleRequestType(event) {
        this.requestTypeResult = event.detail;
        this.requestTypeChosen = true;
        this.fieldValues.Type__c = this.requestTypeResult.type;
        this.setCurrentForm();
    }

    deleteMarkedFiles() {
        this.template.querySelector('c-hot_request-form_request_v2').deleteMarkedFiles();
    }

    async handleSubmit(event) {
        event.preventDefault();
        this.spin = true;
        this.setAccountLookupFieldsBasedOnRequestType();
        this.getFieldValuesFromSubForms();
        let status = 'Åpen';
        if (this.isEditOrCopyMode) {
            this.deleteMarkedFiles();
            status = await getRequestStatus({ recordId: this.recordId });
            if (status !== null && status !== 'Åpen') {
                this.showModalOnEditNotAllowed();
            }
        }
        let hasErrors = this.handleValidation();
        if (!hasErrors && (status === 'Åpen' || status === null)) {
            this.template.querySelector('[data-id="saveButton"]').disabled = true;
            this.promptOverlap().then((overlapOk) => {
                if (overlapOk) {
                    this.hideFormAndShowLoading();
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
        this.fieldValues.OrdererName__c = this.personAccount.Name;
        if (this.requestTypeResult.type === 'Me') {
            this.fieldValues.Account__c = this.personAccount.Id;
        }
    }

    getFieldValuesFromSubForms() {
        this.template.querySelectorAll('.subform').forEach((subForm) => {
            subForm.setFieldValues();
            this.setFieldValuesInWrapper(subForm.getFieldValues());
        });
    }

    setFieldValuesInWrapper(fields) {
        for (let k in fields) {
            this.fieldValues[k] = fields[k];
        }
    }

    setComponentValuesInWrapper(fields) {
        for (let k in fields) {
            this.componentValues[k] = fields[k];
        }
    }

    getComponentValues() {
        let reqForm = this.template.querySelector('c-hot_request-form_request_v2');
        if (reqForm !== null) {
            this.setComponentValuesInWrapper(reqForm.getComponentValues());
        }
        let companyForm = this.template.querySelector('c-hot_request-form_company_v2');
        if (companyForm !== null) {
            this.setComponentValuesInWrapper(companyForm.getComponentValues());
        }
    }

    handleValidation() {
        let hasErrors = false;
        this.template.querySelectorAll('.subform').forEach((subForm) => {
            hasErrors += subForm.validateFields();
        });
        return hasErrors;
    }

    async promptOverlap() {
        this.modalContent = '';
        let response = true;
        let timeInput = this.template.querySelector('c-hot_request-form_request_v2').getTimeInput();

        if (!timeInput.isAdvancedTimes && this.fieldValues.Type__c === 'Me') {
            let duplicateRequests = await checkDuplicates({
                accountId: this.personAccount.Id,
                times: timeInput.times
            });
            if (duplicateRequests.length > 0) {
                this.modalHeader = 'Du har allerede bestillinger i dette tidsrommet.';
                this.noCancelButton = false;
                for (let request of duplicateRequests) {
                    this.modalContent += '\nTema: ' + request.Subject__c;
                    this.modalContent += '\nPeriode: ' + request.SeriesPeriod__c + '\n';
                }
                this.template.querySelector('c-alertdialog').showModal();
                response = false;
            }
        }
        return response;
    }

    handleAlertDialogClick(event) {
        if (event.detail === 'confirm' && this.modalHeader === 'Du har allerede bestillinger i dette tidsrommet.') {
            this.spin = true;
            this.hideFormAndShowLoading();
            this.submitForm();
        }
        if (event.detail === 'cancel' && this.modalHeader === 'Du har allerede bestillinger i dette tidsrommet.') {
            this.template.querySelector('[data-id="saveButton"]').disabled = false;
        }
        if (event.detail === 'confirm' && this.modalHeader === 'Kunne ikke redigere bestilling') {
            this.goToMyRequests();
        }
    }

    submitForm() {
        this.template.querySelector('lightning-record-edit-form').submit(this.fieldValues);
    }

    modalHeader = '';
    modalContent = '';
    noCancelButton = true;
    handleError(event) {
        this.template.querySelector('[data-id="saveButton"]').disabled = false;
        this.modalHeader = 'Noe gikk galt under opprettelsen av bestillingen.';
        this.noCancelButton = true;
        if (event.detail.detail === 'Fant ingen virksomhet med dette organisasjonsnummeret.') {
            this.modalContent =
                'Fant ingen virksomhet med organisasjonsnummer ' + this.fieldValues.OrganizationNumber__c + '.';
        } else {
            this.modalContent = event.detail.detail;
        }
        this.template.querySelector('c-alertdialog').showModal();
        this.spin = false;
    }
    @track requestId;

    handleSuccess(event) {
        const record = event.detail.id;
        this.requestId = record;

        if (this.editNotAllowed) {
            return;
        }
        this.recordId = event.detail.id;
        this.uploadFiles();
        this.createWorkOrders();
        window.scrollTo(0, 0);
    }

    hideFormAndShowSuccess() {
        this.template.querySelector('.submitted-loading').classList.add('hidden');
        this.template.querySelector('.submitted-false').classList.add('hidden');
        this.template.querySelector('.submitted-true').classList.remove('hidden');
        this.template.querySelector('.h2-successMessage').focus();
    }

    hideFormAndShowLoading() {
        this.template.querySelector('.submitted-false').classList.add('hidden');
        this.template.querySelector('.submitted-loading').classList.remove('hidden');
        this.template.querySelector('.h2-loadingMessage').focus();
        window.scrollTo(0, 0);
    }

    hideFormAndShowError() {
        this.template.querySelector('.submitted-loading').classList.add('hidden');
        this.template.querySelector('.submitted-false').classList.add('hidden');
        this.template.querySelector('.submitted-error').classList.remove('hidden');
        this.template.querySelector('.h2-errorMessage').focus();
    }

    editNotAllowed = false;
    showModalOnEditNotAllowed() {
        this.editNotAllowed = true;
        this.noCancelButton = true;
        this.confirmButtonStyle = 'width: 15rem;';
        this.modalContent =
            'En formidler har nettopp begynt å jobbe med bestillingen din, og den kan derfor ikke redigeres.';
        this.modalHeader = 'Kunne ikke redigere bestilling';
        this.template.querySelector('c-alertdialog').showModal();
    }

    uploadFiles() {
        this.template.querySelector('c-hot_request-form_request_v2').handleFileUpload(this.recordId);
    }

    createWorkOrders() {
        let timeInput = this.template.querySelector('c-hot_request-form_request_v2').getTimeInput();
        if (timeInput.times !== {}) {
            if (timeInput.isAdvancedTimes) {
                try {
                    createWorkOrders({
                        requestId: this.recordId,
                        times: timeInput.times['0'],
                        recurringType: timeInput.repeatingOptionChosen,
                        recurringDays: timeInput.chosenDays,
                        recurringEndDate: new Date(timeInput.repeatingEndDate).getTime()
                    }).then(() => {
                        this.spin = false;
                        if (this.isCreatedCorrectly(this.requestId)) {
                            this.hideFormAndShowSuccess();
                        } else {
                            this.hideFormAndShowError();
                        }
                    });
                } catch (error) {
                    console.log(JSON.stringify(error));
                    this.hideFormAndShowError();
                }
            } else {
                createAndUpdateWorkOrders({ requestId: this.recordId, times: timeInput.times }).then(() => {
                    this.spin = false;
                    if (this.isCreatedCorrectly(this.requestId)) {
                        this.hideFormAndShowSuccess();
                    } else {
                        this.hideFormAndShowError();
                    }
                });
            }
        }
    }
    isCreatedCorrectly(recordId) {
        return isErrorOnRequestCreate({
            requestId: recordId
        }).then((result) => {
            if (result === false) {
                return true;
            } else {
                return false;
            }
        });
    }

    @track previousPage = 'home';
    connectedCallback() {
        let parsed_params = getParametersFromURL();
        if (parsed_params != null) {
            if (parsed_params.fromList != null) {
                if (parsed_params.isAccount === 'true') {
                    this.previousPage = 'mine-bestillinger';
                    this.breadcrumbs[this.breadcrumbs.length - 1].label = 'Mine Bestillinger';
                    this.breadcrumbs[this.breadcrumbs.length - 1].href = 'mine-bestillinger';
                } else {
                    this.previousPage = 'mine-bestillinger-andre';
                    this.breadcrumbs[this.breadcrumbs.length - 1].label = 'Bestillinger på vegne av andre';
                    this.breadcrumbs[this.breadcrumbs.length - 1].href = 'mine-bestillinger-andre';
                }
            }
            if (parsed_params.fieldValues != null) {
                this.setFieldValuesFromURL(parsed_params);
            }
        }
    }
    handleUploadFinished(event) {
        const uploadedFiles = event.detail.files;
        if (uploadedFiles.length > 0) {
            this.template.querySelector('c-record-files-with-sharing').refreshContentDocuments();
        }
    }

    submitButtonLabel = 'Send inn';
    submitSuccessMessage = 'Bestilling mottatt';
    isEditOrCopyMode = false;
    showUploadFileModule = true;
    isEditModeAndTypeMe = false;
    handleEditOrCopyModeRequestType(parsed_params) {
        if (parsed_params.edit != null) {
            this.breadcrumbs.push({ label: 'Rediger bestilling' });
            this.submitButtonLabel = 'Lagre';
            this.submitSuccessMessage = 'Dine endringer er lagret';
            this.showUploadFileModule = false;
        }
        if (parsed_params.copy != null) {
            this.breadcrumbs.push({ label: 'Kopier bestilling' });
            this.submitButtonLabel = 'Send inn';
            this.submitSuccessMessage = 'Bestilling mottatt';
        }
        this.isEditOrCopyMode = parsed_params.edit != null || parsed_params.copy != null;
        this.requestTypeChosen = this.isEditOrCopyMode;
        this.isEditModeAndTypeMe = this.fieldValues.Type__c === 'Me' && this.isEditOrCopyMode;
    }

    isGetAll = false;
    setFieldValuesFromURL(parsed_params) {
        this.fieldValues = JSON.parse(parsed_params.fieldValues);
        this.handleEditOrCopyModeRequestType(parsed_params);
        this.userCheckboxValue = this.fieldValues.UserName__c ? true : false;
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
        this.setCurrentForm();
    }
    @track requestIds = [];

    goToMyRequests() {
        let pageName = this.fieldValues.Type__c === 'Me' ? 'mine-bestillinger' : 'mine-bestillinger-andre';
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                pageName: pageName
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

    formArray = [];
    setCurrentForm() {
        const currentFormUserForm = this.template.querySelector('c-hot_request-form_user_v2') !== null;
        const currentFormOrdererForm = this.template.querySelector('c-hot_request-form_orderer_v2') !== null;
        const currentFormCompanyForm = this.template.querySelector('c-hot_request-form_company_v2') !== null;

        if (this.formArray.length === 0 && this.fieldValues.Type__c !== 'Me') {
            this.formArray.push('ordererForm');
        }
        if (currentFormUserForm || currentFormCompanyForm || this.fieldValues.Type__c === 'Me') {
            this.formArray.push('requestForm');
        } else if (currentFormOrdererForm && this.fieldValues.Type__c === 'User') {
            this.formArray.push('userForm');
        } else if (currentFormOrdererForm && this.fieldValues.Type__c === 'Company') {
            this.formArray.push('companyForm');
            if (this.userCheckboxValue) {
                this.formArray.push('userForm');
                this.requestTypeResult[this.formArray[this.formArray.length - 2]] = true;
            }
        }
        this.requestTypeResult[this.formArray[this.formArray.length - 1]] = true;
    }

    userCheckboxValue = true;
    handleUserCheckbox(event) {
        this.userCheckboxValue = event.detail;
        if (event.detail) {
            this.formArray.push('userForm');
            this.requestTypeResult.userForm = true;
        } else {
            this.requestTypeResult[this.formArray[this.formArray.length - 1]] = false;
            this.formArray.pop();
        }
    }

    handleNextButtonClicked() {
        this.getFieldValuesFromSubForms();
        this.getComponentValues();
        if (this.handleValidation()) {
            return;
        }
        if (
            this.formArray[this.formArray.length - 1] === 'userForm' &&
            this.formArray[this.formArray.length - 2] === 'companyForm'
        ) {
            this.requestTypeResult[this.formArray[this.formArray.length - 2]] = false;
        }
        if (this.formArray[this.formArray.length - 1] === 'companyForm' && !this.userCheckboxValue) {
            this.fieldValues.UserName__c = '';
            this.fieldValues.UserPersonNumber__c = '';
        }
        this.requestTypeResult[this.formArray[this.formArray.length - 1]] = false;
        this.setCurrentForm();
    }

    handleBackButtonClicked() {
        window.scrollTo(0, 0);
        this.getFieldValuesFromSubForms();
        this.getComponentValues();
        if (!this.requestTypeChosen) {
            this.previousPage = 'home';
            this.goToPreviousPage();
        }
        if (this.formArray.length < 2) {
            this.resetFormValuesOnTypeSelection();
            if (this.isEditOrCopyMode) {
                this.goToPreviousPage();
            }
        } else if (
            this.formArray[this.formArray.length - 1] === 'userForm' &&
            this.formArray[this.formArray.length - 2] === 'companyForm'
        ) {
            // Back to ordererForm
            this.requestTypeResult[this.formArray[this.formArray.length - 1]] = false;
            this.requestTypeResult[this.formArray[this.formArray.length - 2]] = false;
            this.requestTypeResult[this.formArray[this.formArray.length - 3]] = true;
            this.formArray.pop();
            this.formArray.pop();
        } else if (
            this.formArray[this.formArray.length - 2] === 'userForm' &&
            this.formArray[this.formArray.length - 3] === 'companyForm'
        ) {
            // Back to company+userform (checkbox checked)
            this.requestTypeResult[this.formArray[this.formArray.length - 1]] = false;
            this.requestTypeResult[this.formArray[this.formArray.length - 2]] = true;
            this.requestTypeResult[this.formArray[this.formArray.length - 3]] = true;
            this.formArray.pop();
        } else {
            this.requestTypeResult[this.formArray[this.formArray.length - 1]] = false;
            this.requestTypeResult[this.formArray[this.formArray.length - 2]] = true;
            this.formArray.pop();
        }
    }

    resetFormValuesOnTypeSelection() {
        this.formArray = [];
        this.fieldValues = {};
        this.componentValues = {};
        this.requestTypeChosen = false;
        this.userCheckboxValue = true;
        this.requestTypeResult = null;
    }
}
