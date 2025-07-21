import { LightningElement, track, wire, api } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { updateRecord, getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';

import getMyWorkOrdersAndRelatedRequest from '@salesforce/apex/HOT_WorkOrderListController.getMyWorkOrdersAndRelatedRequest';
import getThreadInterpreterId from '@salesforce/apex/HOT_WorkOrderListController.getThreadInterpreterId';
import getThreadRequestId from '@salesforce/apex/HOT_RequestListController.getThreadRequestId';
import updateRelatedWorkOrders from '@salesforce/apex/HOT_RequestListController.updateRelatedWorkOrders';
import createThread from '@salesforce/apex/HOT_MessageHelper.createThread';
import createThreadOrdererUser from '@salesforce/apex/HOT_MessageHelper.createThreadOrdererUser';

import FILE_CONSENT from '@salesforce/schema/HOT_Request__c.IsFileConsent__c';
import REQUEST_ID from '@salesforce/schema/HOT_Request__c.Id';
import WORKORDER_NOTIFY_DISPATCHER from '@salesforce/schema/WorkOrder.HOT_IsNotifyDispatcher__c';
import WORKORDER_STATUS from '@salesforce/schema/WorkOrder.Status';
import WORKORDER_ID from '@salesforce/schema/WorkOrder.Id';

import USER_ID from '@salesforce/user/Id';
import USER_ACCOUNT_ID from '@salesforce/schema/User.AccountId';

import { formatRecord } from 'c/datetimeFormatterNorwegianTime';
import { defaultFilters, compare } from './filters';

export default class Hot_myRequestsWrapper extends NavigationMixin(LightningElement) {
    @api header;
    @api isAccount;

    @track commonTableColumns = [
        { label: 'Tid', fieldName: 'StartAndEndDate' },
        { label: 'Status', fieldName: 'Status' },
        { label: 'Tema', fieldName: 'Subject' },
        { label: 'Adresse', fieldName: 'Address' }
    ];

    @track labelMap = {
        Status: {
            Completed: { label: 'Ferdig', cssClass: 'label-green' },
            New: { label: 'Åpen', cssClass: 'label-gray' },
            Canceled: { label: 'Avlyst', cssClass: 'label-red' },
            Dispatched: { label: 'Du har fått tolk', cssClass: 'label-green' },
            Scheduled: { label: 'Under behandling', cssClass: 'label-orange' },
            'Partially Complete': { label: 'Ferdig', cssClass: 'label-green' },
            'Cannot Complete': { label: 'Ikke ledig tolk', cssClass: 'label-red' }
        }
    };

    @track userAccountId;
    @track userRecord = { AccountId: null };

    recordId;
    filters = [];

    records = [];
    allRecords = [];
    commonTableRecords = [];
    urlStateParameters = { level: '', id: '' };

    request = { MeetingStreet__c: '', Subject__c: '' };
    workOrder = { HOT_AddressFormated__c: '', Subject: '' };
    workOrders = [];

    fileUploadMessage = '';
    threadDispatcherId;
    workOrderThreadId;

    threadOrdererUserButtonDescription = 'Test';

    isRequestDetails = false;
    isWorkOrderDetails = false;
    isRequestOrWorkOrderDetails = false;

    requestAddressToShow;
    requestInterpretationAddressToShow;
    workOrderInterpretationAddressToShow;

    isCancel = false;
    noCancelButton = true;

    showUploadFilesComponent = false;
    isAddFiles = false;
    showCancelUploadButton = true;

    checkboxValue = false;
    hasFiles = false;
    fileLength;

    filteredRecordsLength = 0;

    isNavigatingAway = false;

    // Some button states and labels
    isRequestEditButtonDisabled = false;
    isRequestCancelButtonDisabled = false;
    isRequestAddFilesButtonDisabled = false;

    isWOEditButtonDisabled = false;
    isWOCancelButtonDisabled = false;
    isWOAddFilesButtonDisabled = false;

    isThreadButtonDisabled = false;
    isInterpreterThreadButtonDisabled = false;
    isTheOrderer = true;

    editButtonLabel = 'Rediger';
    copyButtonLabel = 'Kopier';
    cancelButtonLabel = 'Avlys';
    threadOrdererUserButtonLabel;

    headerToShow = '';

    interpreter = 'Tolk';
    isOrdererWantStatusUpdateOnSMS = 'Ja';
    isSeries = false;
    isUserAccount = false;
    isAccountEqualOrderer = false;
    IsNotNotifyAccount = 'Ja';

    datetimeFields = [
        { name: 'StartAndEndDate', type: 'datetimeinterval', start: 'StartDate', end: 'EndDate' },
        { name: 'HOT_Request__r.SeriesStartDate__c', type: 'date' },
        { name: 'HOT_Request__r.SeriesEndDate__c', type: 'date' },
        { name: 'HOT_Request__r.StartTime__c', type: 'date' },
        { name: 'HOT_Request__r.EndTime__c', type: 'date' }
    ];

    workOrderStartDate = '';
    workOrderEndDate = '';
    requestSeriesStartDate = '';
    requestSeriesEndDate = '';

    // Responsive computed properties
    get isMobile() {
        return window.screen.width < 576;
    }
    get buttonText() {
        return this.isMobile ? '+' : 'Ny bestilling';
    }

    @wire(getRecord, { recordId: USER_ID, fields: [USER_ACCOUNT_ID] })
    wiredUser({ error, data }) {
        if (data) {
            this.userAccountId = getFieldValue(data, USER_ACCOUNT_ID);
            this.userRecord.AccountId = this.userAccountId;
        } else if (error) {
            console.error('Error fetching user account info', error);
        }
    }

    // Wire the work orders and related requests
    wiredgetWorkOrdersResult;
    @wire(getMyWorkOrdersAndRelatedRequest, { isAccount: '$isAccount' })
    wiredgetWorkOrdersHandler(result) {
        this.wiredgetWorkOrdersResult = result;
        if (result.data) {
            const tempRecords = result.data.map((record) => formatRecord({ ...record }, this.datetimeFields));
            this.records = tempRecords;
            // this.noWorkOrders = !this.records.length;
            this.allRecords = [...tempRecords];
            this.commonTableRecords = this.flattenRecords(tempRecords);
            this.refresh(false);
        }
    }

    connectedCallback() {
        refreshApex(this.wiredgetWorkOrdersResult);
        this.filters = defaultFilters();
    }

    renderedCallback() {
        if (this.urlStateParameters.id === '' && this.urlStateParameters.level === '') {
            refreshApex(this.wiredgetWorkOrdersResult);
        }
    }

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference && Object.keys(currentPageReference.state).length > 0 && !this.isNavigatingAway) {
            this.urlStateParameters = { ...currentPageReference.state };
        } else {
            this.urlStateParameters = { level: '', id: '' };
        }
    }

    // Fetch and set current selected record details
    getRecords() {
        this.resetRequestAndWorkOrder();
        const recordId = this.urlStateParameters.id;

        for (const record of this.records) {
            if (recordId === record.Id) {
                this.workOrder = record;
                this.request = record.HOT_Request__r || {};
                this.recordId = this.request.Id;

                getThreadInterpreterId({ workOrderId: this.workOrder.Id })
                    .then((result) => {
                        this.workOrderThreadId = result || undefined;
                    })
                    .catch(() => {
                        this.workOrderThreadId = undefined;
                    });
                break;
            }
        }

        if (this.request.Id) {
            this.getWorkOrders();
        }
    }

    // Flatten records for common table
    flattenRecords(records) {
        return records.map((record) => ({
            Id: record.Id,
            StartAndEndDate: record.StartAndEndDate,
            Status: record.Status,
            Subject: record.HOT_Request__r?.Subject__c,
            Address: record.HOT_AddressFormated__c
        }));
    }

    resetRequestAndWorkOrder() {
        this.request = { MeetingStreet__c: '', Subject__c: '' };
        this.workOrder = { HOT_AddressFormated__c: '', Subject: '' };
    }

    // Date formatting helpers
    setDateFormats() {
        this.workOrderStartDate = this.formatDate(this.workOrder.StartDate, true);
        this.workOrderEndDate = this.formatDate(this.workOrder.EndDate, true);
        this.requestSeriesStartDate = this.formatDate(this.request.SeriesStartDate__c, false);
        this.requestSeriesEndDate = this.formatDate(this.request.SeriesEndDate__c, false);
    }
    formatDate(dateInput, isWorkOrder) {
        if (!dateInput) return '';
        let value = new Date(dateInput).toLocaleString();
        return isWorkOrder ? value.slice(0, -3) : value.slice(0, -10);
    }

    // Button enable/disable logic
    setButtonStates() {
        const tempEndDate = this.isRequestDetails
            ? new Date(this.request.SeriesEndDate__c)
            : new Date(this.workOrder.EndDate);

        const oneYearAgo = new Date();
        oneYearAgo.setFullYear(oneYearAgo.getFullYear() - 1);

        this.isRequestEditButtonDisabled = this.request.Status__c !== 'Åpen';
        this.isRequestCancelButtonDisabled =
            this.request.Status__c === 'Avlyst' || tempEndDate.getTime() < Date.now() || !this.isTheOrderer;

        this.isRequestAddFilesButtonDisabled = this.request.Status__c === 'Avlyst' || tempEndDate <= oneYearAgo;

        this.isWOEditButtonDisabled = this.workOrder.HOT_ExternalWorkOrderStatus__c !== 'Åpen';
        this.isWOCancelButtonDisabled = this.workOrder.HOT_ExternalWorkOrderStatus__c === 'Avlyst';
        this.isWOAddFilesButtonDisabled = this.workOrder.HOT_ExternalWorkOrderStatus__c === 'Avlyst';
    }

    // Header and columns
    setHeader() {
        if (this.urlStateParameters.level === 'R') {
            this.headerToShow = 'Serie: ' + this.request.Subject__c;
        } else if (this.urlStateParameters.id === '') {
            this.headerToShow = this.header;
        } else {
            this.headerToShow = this.workOrder.Subject;
        }
    }

    getWorkOrders() {
        this.workOrders = this.records.filter((record) => record.HOT_Request__c === this.request.Id);
    }

    goToRecordDetails(event) {
        window.scrollTo(0, 0);
        const record = event.detail;
        let level = record.HOT_Request__r?.IsSerieoppdrag__c ? 'R' : 'WO';
        if (this.urlStateParameters.level === 'R') {
            level = 'WO';
        }
        this.urlStateParameters = { id: record.Id, level };
        this.refresh(true);
    }

    // Button label logic
    setButtonLabels() {
        this.isTheOrderer = true;

        if (this.urlStateParameters.level === 'R') {
            this.editButtonLabel = 'Rediger serie';
            this.copyButtonLabel = 'Kopier serie';
            this.cancelButtonLabel = 'Avlys serie';
            this.isThreadButtonDisabled = false;
            this.isInterpreterThreadButtonDisabled = true;
        } else {
            this.editButtonLabel = 'Rediger';
            this.copyButtonLabel = 'Kopier';
            this.cancelButtonLabel = 'Avlys';
            this.isThreadButtonDisabled = false;
            this.isInterpreterThreadButtonDisabled = this.workOrder.HOT_Interpreters__c == null;
        }

        if (!this.request.IsAccountEqualOrderer__c && this.request.Orderer__c === this.userAccountId) {
            this.threadOrdererUserButtonLabel = 'Samtale med bruker';
        } else if (!this.request.IsAccountEqualOrderer__c && this.request.Account__c === this.userRecord.AccountId) {
            this.threadOrdererUserButtonLabel = 'Samtale med bestiller';
            this.isTheOrderer = false;
        }
    }

    // Format addresses depending on digital/physical meeting
    setAddressFormat() {
        const digitalLabel = 'Digitalt oppmøte';
        this.requestAddressToShow = this.request.IsScreenInterpreter__c
            ? digitalLabel
            : `${this.request.MeetingStreet__c}, ${this.request.MeetingPostalCode__c} ${this.request.MeetingPostalCity__c}`;

        this.requestInterpretationAddressToShow = this.request.IsScreenInterpreter__c
            ? digitalLabel
            : `${this.request.InterpretationStreet__c}, ${this.request.InterpretationPostalCode__c} ${this.request.InterpretationPostalCity__c}`;

        this.workOrderInterpretationAddressToShow = this.request.IsScreenInterpreter__c
            ? digitalLabel
            : `${this.workOrder.HOT_InterpretationStreet__c}, ${this.workOrder.HOT_InterpretationPostalCode__c} ${this.workOrder.HOT_InterpretationPostalCity__c}`;
    }

    // Refresh view with options to update URL
    refresh(isUpdateURL) {
        this.getRecords();
        if (isUpdateURL) this.updateURL();
        // this.setColumns();
        this.updateView();
        this.applyFilter({ detail: { filterArray: this.filters, setRecords: true } });
    }

    updateView() {
        this.isUserAccount = this.request.Account__c === this.userRecord.AccountId;
        this.isAccountEqualOrderer = this.request.IsAccountEqualOrderer__c;
        this.isRequestDetails = this.urlStateParameters.level === 'R';
        this.isWorkOrderDetails = this.urlStateParameters.level === 'WO';
        this.isRequestOrWorkOrderDetails = this.isRequestDetails || this.isWorkOrderDetails;
        this.isSeries = this.workOrder?.HOT_Request__r?.IsSerieoppdrag__c;
        this.interpreter = (this.workOrder?.HOT_Interpreters__c?.length || 0) > 1 ? 'Tolker' : 'Tolk';
        this.isOrdererWantStatusUpdateOnSMS = this.request.IsOrdererWantStatusUpdateOnSMS__c ? 'Ja' : 'Nei';
        this.IsNotNotifyAccount = this.request.IsNotNotifyAccount__c ? 'Nei' : 'Ja';
        this.isGetAllFiles = this.request.Account__c === this.userRecord.AccountId;
        this.setHeader();
        this.setButtonLabels();
        this.setButtonStates();
        this.setDateFormats();
        this.setAddressFormat();
    }

    updateURL() {
        let url = `${window.location.protocol}//${window.location.host}${window.location.pathname}`;
        if (this.urlStateParameters.id && this.urlStateParameters.level) {
            url += `?id=${this.urlStateParameters.id}&level=${this.urlStateParameters.level}`;
        }
        window.history.pushState({ path: url }, '', url);
    }

    // Filtering logic
    applyFilter(event) {
        let setRecords = event.detail.setRecords;
        this.filters = event.detail.filterArray;

        let filteredRecords = [];
        let recordsToFilter = this.isRequestDetails ? this.workOrders : this.allRecords;

        for (let record of recordsToFilter) {
            let includeRecord = true;
            for (let filter of this.filters) {
                includeRecord = includeRecord && compare(filter, record);
            }
            if (includeRecord) {
                filteredRecords.push(record);
            }
        }
        this.filteredRecordsLength = filteredRecords.length;

        if (setRecords) {
            this.records = filteredRecords;
            // Also update the common table records with flattened filtered records
            this.commonTableRecords = this.flattenRecords(filteredRecords);
        }
    }

    sendFilteredRecordsLength(event) {
        this.applyFilter(event);
        this.template.querySelector('c-list-filters-button').setFilteredRecordsLength(this.filteredRecordsLength);
    }

    // Edit, clone, cancel and navigation
    editOrder() {
        this.isNavigatingAway = true;
        if (this.request.Orderer__c === this.userRecord.AccountId && this.request.Status__c.includes('Åpen')) {
            this.isGetAllFiles = true;
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: { pageName: 'ny-bestilling' },
                state: {
                    fieldValues: JSON.stringify(this.request),
                    fromList: true,
                    edit: true,
                    isAccount: JSON.stringify(this.isAccount)
                }
            });
        } else {
            this.modalContent =
                'Denne bestillingen er bestilt av noen andre, og du har ikke rettigheter til å endre den.';
            this.showModal();
        }
    }

    cloneOrder() {
        this.isNavigatingAway = true;
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: { pageName: 'ny-bestilling' },
            state: {
                fieldValues: JSON.stringify(this.request),
                fromList: true,
                copy: true,
                isAccount: JSON.stringify(this.isAccount)
            }
        });
    }

    cancelOrder() {
        let tempEndDate = this.isRequestDetails
            ? new Date(this.request.SeriesEndDate__c)
            : new Date(this.workOrder.EndDate);
        if (
            this.request.ExternalRequestStatus__c !== 'Avlyst' &&
            this.request.ExternalRequestStatus__c !== 'Dekket' &&
            tempEndDate.getTime() > Date.now()
        ) {
            if (this.urlStateParameters.level === 'R') {
                this.modalContent = 'Er du sikker på at du vil avlyse alle fremtidige datoer i bestillingen?';
            } else {
                this.modalContent =
                    'Er du sikker på at du vil avlyse bestillingen?\nDato: ' + this.workOrder.StartAndEndDate;
            }
            this.isCancel = true;
            this.noCancelButton = false;
            this.showModal();
        } else {
            this.modalContent = 'Du kan ikke avlyse denne bestillingen.';
            this.noCancelButton = true;
            this.showModal();
        }
    }

    goToNewRequest() {
        this.isNavigatingAway = true;
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                pageName: 'ny-bestilling'
            },
            state: {
                fromList: true,
                isAccount: this.isAccount
            }
        });
    }

    cancelAndRefreshApex() {
        this.showCancelUploadButton = false;
        this.template.querySelector('.ReactModal__Overlay').classList.remove('hidden');
        this.template.querySelector('.loader').classList.remove('hidden');
        const fields = {};
        if (this.urlStateParameters.level === 'R') {
            updateRelatedWorkOrders({ requestId: this.request.Id })
                .then(() => {
                    refreshApex(this.wiredgetWorkOrdersResult);
                    this.noCancelButton = true;
                    this.template.querySelector('.ReactModal__Overlay').classList.add('hidden');
                    this.template.querySelector('.loader').classList.add('hidden');
                    this.modalContent = 'Bestillingen er avlyst.';
                    this.showModal();
                })
                .catch(() => {
                    this.noCancelButton = true;
                    this.template.querySelector('.ReactModal__Overlay').classList.add('hidden');
                    this.template.querySelector('.loader').classList.add('hidden');
                    this.modalContent = 'Kunne ikke avlyse denne bestillingen.';
                    this.showModal();
                });
        } else {
            fields[WORKORDER_ID.fieldApiName] = this.workOrder.Id;
            fields[WORKORDER_STATUS.fieldApiName] = 'Canceled';
            fields[WORKORDER_NOTIFY_DISPATCHER.fieldApiName] = true;
            const recordInput = { fields };
            updateRecord(recordInput)
                .then(() => {
                    refreshApex(this.wiredgetWorkOrdersResult);
                    this.noCancelButton = true;
                    this.template.querySelector('.ReactModal__Overlay').classList.add('hidden');
                    this.template.querySelector('.loader').classList.add('hidden');
                    this.modalContent = 'Bestillingen er avlyst.';
                    this.showModal();
                })
                .catch(() => {
                    this.noCancelButton = true;
                    this.template.querySelector('.ReactModal__Overlay').classList.add('hidden');
                    this.template.querySelector('.loader').classList.add('hidden');
                    this.modalContent = 'Kunne ikke avlyse denne bestillingen.';
                    this.showModal();
                });
        }
    }

    showUploadFilesComponent = false;
    isAddFiles = false;
    addFiles() {
        this.fileUploadMessage = '';
        this.showCancelUploadButton = true;
        this.checkboxValue = false;
        this.isAddFiles = true;
        this.showUploadFilesComponent = true;
        let detailPage = this.template.querySelector('.ReactModal__Overlay');
        detailPage.classList.remove('hidden');
        detailPage.focus();
    }

    showCancelUploadButton = true;
    cancelUploadFiles() {
        this.template.querySelector('.ReactModal__Overlay').classList.add('hidden');
        this.template.querySelector('c-upload-files').clearFileData();
        this.showUploadFilesComponent = false;
    }

    handleFileUpload() {
        if (this.hasFiles) {
            this.template.querySelector('c-upload-files').handleFileUpload(this.request.Id);
        }
    }

    clearFileData() {
        this.template.querySelector('c-upload-files').clearFileData();
    }

    hasFiles = false;
    fileLength;
    checkFileDataLength(event) {
        this.fileLength = event.detail;
        this.hasFiles = event.detail > 0;
    }

    onUploadComplete() {
        if (this.template.querySelector('c-record-files-without-sharing') !== null) {
            this.template.querySelector('c-record-files-without-sharing').refreshContentDocuments();
        }
        this.template.querySelector('.loader').classList.add('hidden');
        this.modalHeader = 'Suksess!';
        // Only show pop-up modal if in add files window
        if (this.isAddFiles) {
            this.showModal();
        }
        this.template.querySelector('.ReactModal__Overlay').classList.add('hidden');
    }

    onUploadError(err) {
        this.template.querySelector('.loader').classList.add('hidden');
        this.modalHeader = 'Noe gikk galt';
        this.modalContent = 'Kunne ikke laste opp fil(er). Feilmelding: ' + err;
        this.showModal();
        this.template.querySelector('.ReactModal__Overlay').classList.add('hidden');
    }

    validateCheckbox() {
        this.template.querySelector('c-upload-files').validateCheckbox();
    }

    checkboxValue = false;
    getCheckboxValue(event) {
        this.checkboxValue = event.detail;
    }

    uploadFilesOnSave() {
        let file = this.fileLength > 1 ? 'Filene' : 'Filen';
        this.modalContent = file + ' ble lagt til i bestillingen.';
        this.validateCheckbox();
        // Show spinner
        if (this.checkboxValue) {
            this.showCancelUploadButton = false;
            this.template.querySelector('.loader').classList.remove('hidden');
            this.showUploadFilesComponent = false;
        }
        this.handleFileUpload();
        this.setFileConsent();
    }

    setFileConsent() {
        let fields = {};
        fields[REQUEST_ID.fieldApiName] = this.request.Id;
        fields[FILE_CONSENT.fieldApiName] = this.checkboxValue;
        const recordInput = { fields };
        updateRecord(recordInput);
    }

    isCancel = false;
    noCancelButton = true;
    modalHeader = 'Varsel';
    modalContent = 'Noe gikk galt';
    isAlertdialogConfirm = false;
    handleAlertDialogClick(event) {
        if (event.detail === 'confirm' && this.isCancel) {
            this.cancelAndRefreshApex();
            this.isCancel = false;
        }
        if (event.detail === 'confirm' && this.modalContent === 'Bestillingen er avlyst.') {
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    pageName: 'mine-bestillinger'
                }
            });
        }
    }

    showModal() {
        this.template.querySelector('c-alertdialog').showModal();
    }

    deleteMarkedFiles() {
        this.template.querySelector('c-record-files-without-sharing').deleteMarkedFiles();
    }

    navigateToThread(recordId) {
        if (this.request.IsAccountEqualOrderer__c == false && this.request.Orderer__c == this.userAccountId) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: recordId,
                    objectApiName: 'Thread__c',
                    actionName: 'view'
                },
                state: {
                    from: 'mine-bestillinger-andre',
                    recordId: this.urlStateParameters.id,
                    level: this.urlStateParameters.level
                }
            });
        } else {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: recordId,
                    objectApiName: 'Thread__c',
                    actionName: 'view'
                },
                state: {
                    from: 'mine-bestillinger',
                    recordId: this.urlStateParameters.id,
                    level: this.urlStateParameters.level
                }
            });
        }
    }
    @track threadDispatcherId;
    goToThread() {
        this.isThreadButtonDisabled = true;
        if (this.request.IsAccountEqualOrderer__c == false && this.request.Orderer__c == this.userAccountId) {
            getThreadRequestId({ requestId: this.request.Id, type: 'HOT_BESTILLER-FORMIDLER' }).then((result) => {
                if (result != '') {
                    this.threadDispatcherId = result;
                    this.navigateToThread(this.threadDispatcherId);
                } else {
                    createThread({ recordId: this.request.Id, accountId: this.request.Orderer__c })
                        .then((result) => {
                            this.navigateToThread(result.Id);
                            refreshApex(this.wiredgetWorkOrdersResult);
                        })
                        .catch((error) => {
                            this.modalHeader = 'Noe gikk galt';
                            this.modalContent = 'Kunne ikke åpne samtale. Feilmelding: ' + error;
                            this.noCancelButton = true;
                            this.showModal();
                        });
                }
            });
        }
        if (this.request.IsAccountEqualOrderer__c == false && this.request.Account__c == this.userAccountId) {
            getThreadRequestId({ requestId: this.request.Id, type: 'HOT_BRUKER-FORMIDLER' }).then((result) => {
                if (result != '') {
                    this.threadDispatcherId = result;
                    this.navigateToThread(this.threadDispatcherId);
                } else {
                    createThread({ recordId: this.request.Id, accountId: this.request.Account__c })
                        .then((result) => {
                            this.navigateToThread(result.Id);
                            refreshApex(this.wiredgetWorkOrdersResult);
                        })
                        .catch((error) => {
                            this.modalHeader = 'Noe gikk galt';
                            this.modalContent = 'Kunne ikke åpne samtale. Feilmelding: ' + error;
                            this.noCancelButton = true;
                            this.showModal();
                        });
                }
            });
        }
        if (this.request.IsAccountEqualOrderer__c == true && this.request.Account__c == this.userAccountId) {
            getThreadRequestId({ requestId: this.request.Id, type: 'HOT_BRUKER-FORMIDLER' }).then((result) => {
                if (result != '') {
                    this.threadDispatcherId = result;
                    this.navigateToThread(this.threadDispatcherId);
                } else {
                    createThread({ recordId: this.request.Id, accountId: this.request.Account__c })
                        .then((result) => {
                            this.navigateToThread(result.Id);
                            refreshApex(this.wiredgetWorkOrdersResult);
                        })
                        .catch((error) => {
                            this.modalHeader = 'Noe gikk galt';
                            this.modalContent = 'Kunne ikke åpne samtale. Feilmelding: ' + error;
                            this.noCancelButton = true;
                            this.showModal();
                        });
                }
            });
        }
    }
    goToThreadInterpreter() {
        this.isInterpreterThreadButtonDisabled = true;
        if (this.workOrderThreadId !== undefined) {
            this.navigateToThread(this.workOrderThreadId);
        } else {
            createThread({ recordId: this.workOrder.Id, accountId: this.request.Account__c })
                .then((result) => {
                    this.navigateToThread(result.Id);
                    refreshApex(this.wiredgetWorkOrdersResult);
                    this.workOrderThreadId = result.Id;
                })
                .catch((error) => {
                    this.modalHeader = 'Noe gikk galt';
                    this.modalContent = 'Kunne ikke åpne samtale. Feilmelding: ' + error;
                    this.noCancelButton = true;
                    this.isThreadButtonDisabled = false;
                    this.showModal();
                });
        }
    }
    goToThreadOrdererUser() {
        getThreadRequestId({ requestId: this.request.Id, type: 'HOT_BRUKER-BESTILLER' }).then((result) => {
            if (result != '') {
                this.threadDispatcherId = result;
                this.navigateToThread(this.threadDispatcherId);
            } else {
                createThreadOrdererUser({ recordId: this.request.Id, accountId: this.request.Account__c })
                    .then((result) => {
                        this.navigateToThread(result.Id);
                        refreshApex(this.wiredgetWorkOrdersResult);
                        this.workOrderThreadId = result.Id;
                    })
                    .catch((error) => {
                        this.modalHeader = 'Noe gikk galt';
                        this.modalContent = 'Kunne ikke åpne samtale. Feilmelding: ' + error;
                        this.noCancelButton = true;
                        this.isThreadButtonDisabled = false;
                        this.showModal();
                    });
            }
        });
    }
}
