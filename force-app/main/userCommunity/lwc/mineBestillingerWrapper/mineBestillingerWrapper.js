import { LightningElement, track, wire, api } from 'lwc';
import getMyWorkOrdersAndRelatedRequest from '@salesforce/apex/HOT_WorkOrderListController.getMyWorkOrdersAndRelatedRequest';
import createThread from '@salesforce/apex/HOT_MessageHelper.createThread';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { columns, mobileColumns, workOrderColumns, workOrderMobileColumns, iconByValue } from './columns';
import { defaultFilters, compare } from './filters';
import getPersonAccount from '@salesforce/apex/HOT_Utility.getPersonAccount';
import FILE_CONSENT from '@salesforce/schema/HOT_Request__c.IsFileConsent__c';
import NOTIFY_DISPATCHER from '@salesforce/schema/HOT_Request__c.IsNotifyDispatcher__c';
import STATUS from '@salesforce/schema/HOT_Request__c.Status__c';
import REQUEST_ID from '@salesforce/schema/HOT_Request__c.Id';
import WORKORDER_NOTIFY_DISPATCHER from '@salesforce/schema/WorkORder.HOT_IsNotifyDispatcher__c';
import WORKORDER_STATUS from '@salesforce/schema/WorkOrder.Status';
import WORKORDER_ID from '@salesforce/schema/WorkOrder.Id';
import { refreshApex } from '@salesforce/apex';
import { updateRecord } from 'lightning/uiRecordApi';

export default class MineBestillingerWrapper extends NavigationMixin(LightningElement) {
    @api header;
    @api isAccount;
    @track filters = [];
    @track breadcrumbs = [];


    get isMobile() {
        return window.screen.width < 576;
    }

    get buttonText() {
        return this.isMobile ? '+' : 'Ny bestilling';
    }
    
    connectedCallback() {
        this.filters = defaultFilters();
        this.breadcrumbs = [ 
        {
            label: 'Tolketjenesten',
            href: ''
        },
        {
            label: this.header,
            href: 'mine-bestillinger'
        }
        ];
    }
    renderedCallback() {
        if (this.urlStateParameters.id === '' && this.urlStateParameters.level === '') {
            refreshApex(this.wiredgetWorkOrdersResult);
        }
    }

    isRequestDetails = false;
    isWorkOrderDetails = false;
    isRequestOrWorkOrderDetails = false;
    @track urlStateParameters = { level: '', id: '' };
    @track columns;
    @track iconByValue = iconByValue;

    @track records = [];
    @track allRecords = [];
    noWorkOrders = false;
    wiredgetWorkOrdersResult;
    @wire(getMyWorkOrdersAndRelatedRequest, { isAccount: '$isAccount' })
    wiredgetWorkOrdersHandler(result) {
        this.wiredgetWorkOrdersResult = result;
        if (result.data) {
            this.records = [...result.data];
            this.noWorkOrders = this.records.length === 0;
            this.allRecords = [...result.data];
            this.refresh(false);
        }
    }

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (
            currentPageReference &&
            Object.keys(currentPageReference.state).length > 0 &&
            this.isNavigatingAway === false
        ) {
            this.urlStateParameters = { ...currentPageReference.state };
            this.refresh(false);
        }
    }
    @track request = { MeetingStreet__c: '', Subject__c: '' };
    @track workOrder = { HOT_AddressFormated__c: '', Subject: '' };
    @track workOrders = [];

    getRecords() {
        this.resetRequestAndWorkOrder();
        let recordId = this.urlStateParameters.id;
        for (let record of this.records) {
            if (recordId === record.Id) {
                this.workOrder = record;
                this.request = record.HOT_Request__r;
            }
        }
        if (this.request.Id !== undefined) {
            this.getWorkOrders();
        }
    }

    resetRequestAndWorkOrder() {
        this.request = { MeetingStreet__c: '', Subject__c: '' };
        this.workOrder = { HOT_AddressFormated__c: '', Subject: '' };
    }

    workOrderStartDate = '';
    workOrderEndDate = '';
    requestSeriesStartDate = '';
    requestSeriesEndDate = '';
    setDateFormats() {
        this.workOrderStartDate = this.formatDate(this.workOrder.StartDate, true);
        this.workOrderEndDate = this.formatDate(this.workOrder.EndDate, true);
        this.requestSeriesStartDate = this.formatDate(this.request.SeriesStartDate__c, false);
        this.requestSeriesEndDate = this.formatDate(this.request.SeriesEndDate__c, false);
    }

    formatDate(dateInput, isWorkOrder) {
        let value = new Date(dateInput);
        value = value.toLocaleString();
        if (isWorkOrder) {
            return value.substring(0, value.length - 3);
        }
        return value.substring(0, value.length - 10);
    }

    isRequestEditButtonDisabled = false;
    isRequestCancelButtonDisabled = false;
    isRequestAddFilesButtonDisabled = false;
    isWOEditButtonDisabled = false;
    isWOCancelButtonDisabled = false;
    isWOAddFilesButtonDisabled = false;
    setButtonStates() {
        let tempEndDate = this.isRequestDetails
            ? new Date(this.request.SeriesEndDate__c)
            : new Date(this.workOrder.EndDate);
        this.isRequestEditButtonDisabled = this.request.Status__c === 'Åpen' ? false : true;
        this.isRequestCancelButtonDisabled =
            this.request.Status__c === 'Avlyst' || tempEndDate.getTime() < Date.now() ? true : false;
        this.isRequestAddFilesButtonDisabled = this.request.Status__c !== 'Avlyst' ? false : true;
        this.isWOEditButtonDisabled = this.workOrder.HOT_ExternalWorkOrderStatus__c === 'Åpen' ? false : true;
        this.isWOCancelButtonDisabled = this.workOrder.HOT_ExternalWorkOrderStatus__c === 'Avlyst' ? true : false;
        this.isWOAddFilesButtonDisabled = this.workOrder.HOT_ExternalWorkOrderStatus__c !== 'Avlyst' ? false : true;
    }

    headerToShow = '';
    setHeader() {
        this.headerToShow =
            this.urlStateParameters.level === 'R' ? 'Serie: ' + this.request.Subject__c : this.workOrder.Subject;
        if (this.urlStateParameters.id === '') {
            this.headerToShow = this.header;
        }
    }
    setColumns() {
        if (window.screen.width > 576) {
            this.columns = this.urlStateParameters.level === 'R' ? workOrderColumns : columns;
        } else {
            this.columns = this.urlStateParameters.level === 'R' ? workOrderMobileColumns : mobileColumns;
        }
    }

    getWorkOrders() {
        let workOrders = [];
        for (let record of this.records) {
            if (record.HOT_Request__c === this.request.Id) {
                workOrders.push(record);
            }
        }
        this.workOrders = workOrders;
    }

    goToRecordDetails(result) {
        window.scrollTo(0, 0);
        let record = result.detail;
        let recordId = record.Id;
        let level = record.HOT_Request__r.IsSerieoppdrag__c ? 'R' : 'WO';
        if (this.urlStateParameters.level === 'R') {
            level = 'WO';
        }
        this.urlStateParameters.id = recordId;
        this.urlStateParameters.level = level;
        this.refresh(true);
    }

    editButtonLabel = 'Rediger';
    copyButtonLabel = 'Kopier';
    cancelButtonLabel = 'Avlys';
    setButtonLabels() {
        if (this.urlStateParameters.level === 'R') {
            this.editButtonLabel = 'Rediger serie';
            this.copyButtonLabel = 'Kopier serie';
            this.cancelButtonLabel = 'Avlys serie';
        } else {
            this.editButtonLabel = 'Rediger';
            this.copyButtonLabel = 'Kopier';
            this.cancelButtonLabel = 'Avlys';
        }
    }

    requestAddressToShow;
    requestInterpretationAddressToShow;
    workOrderInterpretationAddressToShow;
    setAddressFormat() {
        this.requestAddressToShow = this.request.IsScreenInterpreter__c
            ? 'Digitalt oppmøte'
            : this.request.MeetingStreet__c + ', ' + this.request.MeetingPostalCode__c + ' ' + this.request.MeetingPostalCity__c;
        this.requestInterpretationAddressToShow = this.request.IsScreenInterpreter__c
            ? 'Digitalt oppmøte'
            : this.request.InterpretationStreet__c + ', ' + this.request.InterpretationPostalCode__c + ' ' + this.request.InterpretationPostalCity__c;
        this.workOrderInterpretationAddressToShow = this.request.IsScreenInterpreter__c
        ? 'Digitalt oppmøte'
        : this.workOrder.HOT_InterpretationStreet__c + ', ' + this.workOrder.HOT_InterpretationPostalCode__c + ' ' + this.workOrder.HOT_InterpretationPostalCity__c;
    }

    goBack() {
        let currentLevel = this.urlStateParameters.level;
        if (currentLevel === undefined || currentLevel === '') {
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    pageName: 'home'
                }
            });
        }
        let goThroughRequest = this.workOrder?.HOT_Request__r?.IsSerieoppdrag__c;
        if (currentLevel === 'WO' && goThroughRequest) {
            this.urlStateParameters.level = 'R';
        } else {
            this.urlStateParameters.id = '';
            this.urlStateParameters.level = '';
        }
        this.refresh(true);
    }

    refresh(isUpdateURL) {
        this.getRecords();
        if (isUpdateURL) {
            this.updateURL();
        }
        this.setColumns();
        this.updateView();
        this.applyFilter({ detail: { filterArray: this.filters, setRecords: true } });
        console.log(this.isWorkOrderDetails);
    }

    interpreter = 'Tolk';
    isOrdererWantStatusUpdateOnSMS = 'Ja';
    isSeries = false;
    isUserAccount = false;
    updateView() {
        this.isUserAccount = this.request.Account__c === this.userRecord.AccountId;
        this.isRequestDetails = this.urlStateParameters.level === 'R';
        this.isWorkOrderDetails = this.urlStateParameters.level === 'WO';
        this.isRequestOrWorkOrderDetails = this.isWorkOrderDetails || this.isRequestDetails;
        this.isSeries = this.workOrder?.HOT_Request__r?.IsSerieoppdrag__c;
        this.interpreter = this.workOrder?.HOT_Interpreters__c?.length > 1 ? 'Tolker' : 'Tolk';
        this.isOrdererWantStatusUpdateOnSMS = this.request.IsOrdererWantStatusUpdateOnSMS__c ? 'Ja' : 'Nei';
        this.isGetAllFiles = this.request.Account__c === this.userRecord.AccountId ? true : false;
        this.setHeader();
        this.setButtonLabels();
        this.setButtonStates();
        this.setDateFormats();
        this.setAddressFormat();
    }
    updateURL() {
        let refresh = window.location.protocol + '//' + window.location.host + window.location.pathname;
        if (this.urlStateParameters.id !== '' && this.urlStateParameters.level !== '') {
            refresh += '?id=' + this.urlStateParameters.id + '&level=' + this.urlStateParameters.level;
        }
        window.history.pushState({ path: refresh }, '', refresh);
    }

    filteredRecordsLength = 0;
    applyFilter(event) {
        let setRecords = event.detail.setRecords;
        this.filters = event.detail.filterArray;

        let filteredRecords = [];
        let records = this.isRequestDetails ? this.workOrders : this.allRecords;
        for (let record of records) {
            let includeRecord = true;
            for (let filter of this.filters) {
                includeRecord *= compare(filter, record);
            }
            if (includeRecord) {
                filteredRecords.push(record);
            }
        }
        this.filteredRecordsLength = filteredRecords.length;

        if (setRecords) {
            this.records = filteredRecords;
        }
    }

    sendFilteredRecordsLength(event) {
        this.applyFilter(event);
        this.template.querySelector('c-list-filters-button').setFilteredRecordsLength(this.filteredRecordsLength);
    }

    @track userRecord = { AccountId: null };
    @wire(getPersonAccount)
    wiredGetRecord({ data }) {
        if (data) {
            this.userRecord.AccountId = data.AccountId;
        }
    }

    isGetAllFiles = false;
    isNavigatingAway = false;
    editOrder() {
        this.isNavigatingAway = true;
        if (this.request.Orderer__c === this.userRecord.AccountId) {
            this.isGetAllFiles = true;
            if (this.request.Status__c.includes('Åpen')) {
                this[NavigationMixin.Navigate]({
                    type: 'comm__namedPage',
                    attributes: {
                        pageName: 'ny-bestilling'
                    },
                    state: {
                        fieldValues: JSON.stringify(this.request),
                        fromList: true,
                        edit: true,
                        isAccount: JSON.stringify(this.isAccount)
                    }
                });
            }
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
            attributes: {
                pageName: 'ny-bestilling'
            },
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
            this.modalContent = 'Er du sikker på at du vil avlyse bestillingen?';
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
            fields[REQUEST_ID.fieldApiName] = this.request.Id;
            fields[STATUS.fieldApiName] = 'Avlyst';
            fields[NOTIFY_DISPATCHER.fieldApiName] = true;
        } else {
            fields[WORKORDER_ID.fieldApiName] = this.workOrder.Id;
            fields[WORKORDER_STATUS.fieldApiName] = 'Canceled';
            fields[WORKORDER_NOTIFY_DISPATCHER.fieldApiName] = true;
        }
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

    showUploadFilesComponent = false;
    isAddFiles = false;
    addFiles() {
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
        if (this.template.querySelector('c-record-files-with-sharing') !== null) {
            this.template.querySelector('c-record-files-with-sharing').refreshContentDocuments();
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

    noCancelButton = true;
    modalHeader = 'Varsel';
    modalContent = 'Noe gikk galt';
    isAlertdialogConfirm = false;
    handleAlertDialogClick(event) {
        if (event.detail === 'confirm' && this.modalContent === 'Er du sikker på at du vil avlyse bestillingen?') {
            this.cancelAndRefreshApex();
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
        this.template.querySelector('c-record-files-with-sharing').deleteMarkedFiles();
    }

    navigateToThread(recordId) {
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

    goToThread() {
        console.log('this.request.Thread__c: ', this.request.Thread__c);
        if (this.request.Thread__c !== undefined) {
            this.navigateToThread(this.request.Thread__c);
        } else {
            createThread({ recordId: this.request.Id, accountId: this.request.Account__c }).then((result) => {
                this.navigateToThread(result.Id);
                refreshApex(this.wiredgetWorkOrdersResult);
            }).catch((error) => {
                this.modalHeader = 'Noe gikk galt';
                this.modalContent = 'Kunne ikke åpne samtale. Feilmelding: ' + error;
                this.noCancelButton = true;
                this.showModal();
                });
        }
    }
}
