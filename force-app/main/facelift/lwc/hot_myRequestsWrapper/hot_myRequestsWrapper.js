import { LightningElement, wire, api } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { updateRecord, getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';

import getMyWorkOrdersAndRelatedRequest from '@salesforce/apex/HOT_WorkOrderListController.getMyWorkOrdersAndRelatedRequest';
import getThreadInterpreterId from '@salesforce/apex/HOT_WorkOrderListController.getThreadInterpreterId';
import getThreadRequestId from '@salesforce/apex/HOT_RequestListController.getThreadRequestId';
import updateRelatedWorkOrders from '@salesforce/apex/HOT_RequestListController.updateRelatedWorkOrders';
import createThread from '@salesforce/apex/HOT_MessageHelper.createThread';
import createThreadOrdererUser from '@salesforce/apex/HOT_MessageHelper.createThreadOrdererUser';

import { columns, workOrderColumns, labelMap } from './columns';
import { defaultFilters, compare } from './filters';
import FILE_CONSENT from '@salesforce/schema/HOT_Request__c.IsFileConsent__c';
import REQUEST_ID from '@salesforce/schema/HOT_Request__c.Id';
import WORKORDER_NOTIFY_DISPATCHER from '@salesforce/schema/WorkOrder.HOT_IsNotifyDispatcher__c';
import WORKORDER_STATUS from '@salesforce/schema/WorkOrder.Status';
import WORKORDER_ID from '@salesforce/schema/WorkOrder.Id';
import USER_ID from '@salesforce/user/Id';
import USER_ACCOUNT_ID from '@salesforce/schema/User.AccountId';

import { formatRecord, formatDatetime, formatDate } from 'c/datetimeFormatterNorwegianTime';
import icons from '@salesforce/resourceUrl/ikoner';

export default class Hot_myRequestsWrapper extends NavigationMixin(LightningElement) {
    exitCrossIcon = icons + '/Close/Close.svg';
    @api header;
    @api isAccount;
    recordId;
    filters = [];
    labelMap = labelMap;
    showLoader = false;
    shouldFocusHeader = false;
    get isMobile() {
        return window.screen.width < 768;
    }

    userAccountId;
    userRecord = { AccountId: null };

    @wire(getRecord, { recordId: USER_ID, fields: [USER_ACCOUNT_ID] })
    wiredUser({ error, data }) {
        if (data) {
            this.userAccountId = getFieldValue(data, USER_ACCOUNT_ID);
            this.userRecord.AccountId = this.userAccountId;
        } else if (error) {
            console.error('Error fetching user account info', error);
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
        if (this.shouldFocusHeader) {
            this.shouldFocusHeader = false;
            this.focusHeader();
        }
    }
    focusHeader() {
        requestAnimationFrame(() => {
            const el = this.template?.querySelector('.header');
            if (el) {
                el.focus();
            }
        });
    }

    fileUploadMessage = '';
    handleUploadFinished(event) {
        const uploadedFiles = event.detail?.files || [];
        if (uploadedFiles.length > 0) {
            this.fileUploadMessage = 'Filen(e) ble lastet opp';
            this.template
                .querySelectorAll('c-record-files-without-sharing')
                .forEach((cmp) => cmp.refreshContentDocuments());
        }
    }

    isRequestDetails = false;
    isWorkOrderDetails = false;
    isRequestOrWorkOrderDetails = false;
    urlStateParameters = { level: '', id: '' };
    columns;

    records = [];
    allRecords = [];
    viewRows = [];
    noWorkOrders = false;
    wiredgetWorkOrdersResult;
    @wire(getMyWorkOrdersAndRelatedRequest, { isAccount: '$isAccount' })
    wiredgetWorkOrdersHandler(result) {
        this.wiredgetWorkOrdersResult = result;
        if (result.data) {
            const tempRecords = result.data.map((rec) => formatRecord({ ...rec }, this.datetimeFields));
            this.records = tempRecords;
            this.noWorkOrders = this.records.length === 0;
            this.allRecords = [...tempRecords];
            this.viewRows = this.flattenRecords(this.records);
            this.refresh(false);
        }
    }

    datetimeFields = [
        { name: 'StartAndEndDate', type: 'datetimeinterval', start: 'StartDate', end: 'EndDate' },
        { name: 'HOT_Request__r.SeriesStartDate__c', type: 'date' },
        { name: 'HOT_Request__r.SeriesEndDate__c', type: 'date' },
        { name: 'HOT_Request__r.StartTime__c', type: 'date' },
        { name: 'HOT_Request__r.EndTime__c', type: 'date' }
    ];

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (
            currentPageReference &&
            Object.keys(currentPageReference.state).length > 0 &&
            this.isNavigatingAway === false
        ) {
            this.urlStateParameters = { ...currentPageReference.state };
        } else {
            this.urlStateParameters = { level: '', id: '' };
        }
    }

    request = { MeetingStreet__c: '', Subject__c: '' };
    workOrder = { HOT_AddressFormated__c: '', Subject: '' };
    workOrders = [];
    workOrderThreadId;

    getRecords() {
        this.resetRequestAndWorkOrder();
        const recordId = this.urlStateParameters.id;
        for (let record of this.records) {
            if (recordId === record.Id) {
                this.workOrder = record;
                this.request = record.HOT_Request__r;
                this.recordId = record.HOT_Request__r.Id;
            }
        }
        if (this.request.Id !== undefined) {
            this.getWorkOrders();
        }
    }

    // Flatten records for common table
    flattenRecords(records) {
        return records.map((record) => ({
            Id: record.Id,
            StartAndEndDate: record.StartAndEndDate,
            Status: record?.HOT_ExternalWorkOrderStatus__c ?? record.Status,
            Subject: record.HOT_Request__r?.Subject__c,
            HOT_AddressFormated__c: record.HOT_AddressFormated__c,
            HOT_Interpreters__c: record.HOT_Interpreters__c
        }));
    }

    get isOwnRequest() {
        return this.request.Orderer__c === this.userAccountId;
    }

    get uploadTargetId() {
        return this.urlStateParameters?.level === 'WO' ? this.workOrder?.Id : this.request?.Id;
    }

    get getRelatedRecord() {
        return this.uploadTargetId;
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
        this.workOrderStartDate = formatDatetime(this.workOrder.StartDate);
        this.workOrderEndDate = formatDatetime(this.workOrder.EndDate);
        this.requestSeriesStartDate = formatDate(this.request.SeriesStartDate__c);
        this.requestSeriesEndDate = formatDate(this.request.SeriesEndDate__c);
    }
    isRequestEditButtonDisabled = false;
    isRequestCancelButtonDisabled = false;
    isRequestAddFilesButtonDisabled = false;
    isWOEditButtonDisabled = false;
    isWOCancelButtonDisabled = false;
    isWOAddFilesButtonDisabled = false;
    setButtonStates() {
        const tempEndDate = this.isRequestDetails
            ? new Date(this.request.SeriesEndDate__c)
            : new Date(this.workOrder.EndDate);
        const oneYearAgo = new Date(new Date().setFullYear(new Date().getFullYear() - 1));
        this.isRequestEditButtonDisabled = this.request.Status__c === 'Åpen' ? false : true;
        this.isRequestCancelButtonDisabled =
            this.request.Status__c === 'Avlyst' || tempEndDate.getTime() < Date.now() || this.isTheOrderer == false
                ? true
                : false;
        this.isRequestAddFilesButtonDisabled =
            this.request.Status__c !== 'Avlyst' && tempEndDate > oneYearAgo ? false : true;
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
        this.columns = this.urlStateParameters.level === 'R' ? workOrderColumns : columns;
    }

    getWorkOrders() {
        this.workOrders = this.records.filter((record) => record.HOT_Request__c === this.request.Id);
    }

    goToRecordDetails(event) {
        window.scrollTo(0, 0);
        const record = event?.detail?.row ?? event?.detail ?? {};
        const recordId = record.Id;
        const fullRecord = this.records.find((r) => r.Id === recordId);
        if (!fullRecord) {
            return;
        }

        let level = fullRecord?.HOT_Request__r?.IsSerieoppdrag__c ? 'R' : 'WO';
        if (this.urlStateParameters.level === 'R') {
            level = 'WO';
        }
        this.urlStateParameters = { ...this.urlStateParameters, id: recordId, level };
        this.shouldFocusHeader = true;
        this.refresh(true);
    }

    editButtonLabel = 'Rediger';
    copyButtonLabel = 'Kopier';
    cancelButtonLabel = 'Avlys';
    uploadFileButtonLabel = 'Legg til filer';
    uploadFileTitle = 'Legg ved filer til denne bestillingen.';
    uploadFileFormLabel =
        'Ved å laste opp filer er jeg klar over at filene vil bli delt med formidler og tolken(e) jeg får. Opplastingen vil starte umiddelbart. Maks filstørelse: 2 GB.';
    threadOrdererUserButtonLabel;
    isThreadButtonDisabled = false;
    isInterpreterThreadButtonDisabled = false;
    isTheOrderer = true;

    setButtonLabels() {
        this.isTheOrderer = true;

        if (this.urlStateParameters.level === 'R') {
            this.editButtonLabel = 'Rediger serie';
            this.copyButtonLabel = 'Kopier serie';
            this.cancelButtonLabel = 'Avlys serie';
            this.uploadFileButtonLabel = 'Legg til filer på serie';
            this.uploadFileTitle = 'Legg ved filer til hele bestillingen.';
            this.uploadFileFormLabel =
                'Når du laster opp filer her, vil filene bli lagt til på alle tidspunkt i din bestilling. Ved å laste opp filer er jeg klar over at filene vil bli delt med formidler og tolken(e) jeg får. Opplastingen vil starte umiddelbart. Maks filstørrelse: 2 GB.';
            this.isThreadButtonDisabled = false;
            this.isInterpreterThreadButtonDisabled = true;
        } else {
            this.editButtonLabel = 'Rediger';
            this.copyButtonLabel = 'Kopier';
            this.cancelButtonLabel = 'Avlys';
            this.uploadFileButtonLabel = 'Legg til filer';
            this.uploadFileTitle = 'Legg ved filer til denne bestillingen.';
            this.uploadFileFormLabel =
                'Filene du laster opp her, blir kun tilgjengelig på det tidspunkt du har valgt. Ved å laste opp filer er jeg klar over at filene vil bli delt med formidler og tolken(e) jeg får. Opplastingen vil starte umiddelbart. Maks filstørrelse: 2 GB.';
            this.isThreadButtonDisabled = false;
            this.isInterpreterThreadButtonDisabled = this.workOrder.HOT_Interpreters__c == null;
        }
        if (this.request.IsAccountEqualOrderer__c == false && this.request.Orderer__c == this.userAccountId) {
            this.threadOrdererUserButtonLabel = 'Samtale med bruker';
        } else if (
            this.request.IsAccountEqualOrderer__c == false &&
            this.request.Account__c === this.userRecord.AccountId
        ) {
            this.threadOrdererUserButtonLabel = 'Samtale med bestiller';
            this.isTheOrderer = false;
        }
    }

    requestAddressToShow;
    requestInterpretationAddressToShow;
    workOrderInterpretationAddressToShow;
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
        if (isUpdateURL) {
            this.updateURL();
        }
        this.setColumns();
        this.updateView();
        this.applyFilter({ detail: { filterArray: this.filters, setRecords: true } });
    }

    interpreter = 'Tolk';
    showInterpretes = false;
    isOrdererWantStatusUpdateOnSMS = 'Ja';
    isSeries = false;
    isUserAccount = false;
    updateView() {
        this.isUserAccount = this.request.Account__c === this.userRecord.AccountId;
        this.isAccountEqualOrderer = this.request.IsAccountEqualOrderer__c;
        this.isRequestDetails = this.urlStateParameters.level === 'R';
        this.isWorkOrderDetails = this.urlStateParameters.level === 'WO';
        this.isRequestOrWorkOrderDetails = this.isWorkOrderDetails || this.isRequestDetails;
        this.isSeries = this.workOrder?.HOT_Request__r?.IsSerieoppdrag__c;
        this.interpreter = this.workOrder?.HOT_Interpreters__c?.length > 1 ? 'Tolker' : 'Tolk';
        this.showInterpretes =
            this.workOrder?.Status === 'Completed' ||
            this.workOrder?.Status === 'Partially Complete' ||
            this.workOrder?.Status === 'Dispatched';
        this.isOrdererWantStatusUpdateOnSMS = this.request.IsOrdererWantStatusUpdateOnSMS__c ? 'Ja' : 'Nei';
        this.IsNotNotifyAccount = this.request.IsNotNotifyAccount__c ? 'Nei' : 'Ja';
        this.isGetAllFiles = this.request.Account__c === this.userRecord.AccountId ? true : false;
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
    filteredRecordsLength = 0;
    noFilteredRecords = false;
    applyFilter(event) {
        const setRecords = event.detail.setRecords;
        this.filters = event.detail.filterArray;

        const filteredRecords = [];
        const recordsToFilter = this.isRequestDetails ? this.workOrders : this.allRecords;

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
        this.noFilteredRecords = recordsToFilter.length > 0 && filteredRecords.length === 0;

        if (setRecords) {
            this.records = filteredRecords.map((r) => ({ ...r }));
            this.viewRows = this.flattenRecords(filteredRecords);
        }
    }

    sendFilteredRecordsLength(event) {
        this.applyFilter(event);
        this.template.querySelector('c-list-filters-button').setFilteredRecordsLength(this.filteredRecordsLength);
    }
    isGetAllFiles = false;
    isNavigatingAway = false;

    // Edit, clone, cancel and navigation
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
        this.isRequestCancelButtonDisabled = true;
        const tempEndDate = this.isRequestDetails
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
            this.isCancelButton = true;
            this.showModalContent = true;
            this.showModal();
        } else {
            this.modalContent = 'Du kan ikke avlyse denne bestillingen.';
            this.isCancelButton = false;
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

    async cancelAndRefreshApex() {
        this.isNotSubmitted = false;
        this.showCancelUploadButton = false;
        this.showSubmittedLoading = true;
        this.showModalContent = false;
        const fields = {};
        if (this.urlStateParameters.level === 'R') {
            try {
                await updateRelatedWorkOrders({ requestId: this.request.Id });
                await refreshApex(this.wiredgetWorkOrdersResult);
                this.refresh(false);
                this.isCancelButton = false;
                this.showSubmittedLoading = false;
                this.showSubmittedTrue = true;
                this.showModalContent = true;
                this.modalContent = 'Bestillingen er avlyst.';
                this.showModal();
            } catch (e) {
                this.isCancelButton = false;
                this.showSubmittedLoading = false;
                this.showModalContent = true;
                this.showSubmittedError = true;
                this.modalContent = 'Kunne ikke avlyse denne bestillingen.';
                this.showModal();
            }
        } else {
            fields[WORKORDER_ID.fieldApiName] = this.workOrder.Id;
            fields[WORKORDER_STATUS.fieldApiName] = 'Canceled';
            fields[WORKORDER_NOTIFY_DISPATCHER.fieldApiName] = true;
            const recordInput = { fields };
            try {
                await updateRecord(recordInput);
                await refreshApex(this.wiredgetWorkOrdersResult);
                this.refresh(false);
                this.isCancelButton = false;
                this.showSubmittedLoading = false;
                this.showModalContent = true;
                this.showSubmittedTrue = true;
                this.modalContent = 'Bestillingen er avlyst.';
                this.showModal();
            } catch (e) {
                this.isCancelButton = false;
                this.showSubmittedLoading = false;
                this.showModalContent = true;
                this.showSubmittedError = true;
                this.modalContent = 'Kunne ikke avlyse denne bestillingen.';
                this.showModal();
            }
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
        const detailPage = this.template.querySelector('.ReactModal__Overlay');
        detailPage.classList.remove('hidden');
        detailPage.focus();
    }

    showCancelUploadButton = true;
    cancelUploadFiles() {
        this.template.querySelector('.ReactModal__Overlay').classList.add('hidden');
        this.template.querySelector('c-upload-files')?.clearFileData();
        this.showUploadFilesComponent = false;
    }

    handleFileUpload() {
        if (this.hasFiles && this.uploadTargetId) {
            this.template.querySelector('c-upload-files')?.handleFileUpload(this.uploadTargetId);
        }
    }

    clearFileData() {
        this.template.querySelector('c-upload-files')?.clearFileData();
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
        this.showLoader = false;
        this.modalHeader = 'Suksess!';
        // Only show pop-up modal if in add files window
        if (this.isAddFiles) {
            this.showModal();
        }
        this.template.querySelector('.ReactModal__Overlay').classList.add('hidden');
    }

    onUploadError(err) {
        this.showLoader = false;
        this.modalHeader = 'Noe gikk galt';
        this.modalContent = 'Kunne ikke laste opp fil(er). Feilmelding: ' + err;
        this.showModal();
        this.template.querySelector('.ReactModal__Overlay').classList.add('hidden');
    }

    validateCheckbox() {
        this.template.querySelector('c-upload-files')?.validateCheckbox();
    }

    checkboxValue = false;
    getCheckboxValue(event) {
        this.checkboxValue = event.detail;
    }

    uploadFilesOnSave() {
        const file = this.fileLength > 1 ? 'Filene' : 'Filen';
        this.modalContent = file + ' ble lagt til i bestillingen.';
        this.validateCheckbox();
        // Show spinner
        if (this.checkboxValue) {
            this.showCancelUploadButton = false;
            this.showLoader = true;
            this.showUploadFilesComponent = false;
        }
        this.handleFileUpload();
        this.setFileConsent();
    }

    setFileConsent() {
        const fields = {};
        fields[REQUEST_ID.fieldApiName] = this.request.Id;
        fields[FILE_CONSENT.fieldApiName] = this.checkboxValue;
        const recordInput = { fields };
        updateRecord(recordInput);
    }

    showSubmittedLoading = false;
    showSubmittedError = false;
    showSubmittedTrue = false;
    showModalContent = false;
    isNotSubmitted = true;

    isCancel = false;
    isCancelButton = false;
    modalHeader = 'Varsel';
    modalContent = 'Noe gikk galt';
    isAlertdialogConfirm = false;
    alertButtonLabelConfirm = 'Ja';

    handleAlertDialogClick() {
        if (this.isCancel) {
            this.cancelAndRefreshApex();
            this.isCancel = false;
            this.alertButtonLabelConfirm = 'Ok';
        } else {
            this.alertButtonLabelConfirm = 'Ja';
            this.closeModal();
        }
    }
    closeModal() {
        this.setButtonStates();
        const dialog = this.template.querySelector('dialog');
        dialog.close();
    }

    showModal() {
        const dialog = this.template.querySelector('dialog');
        dialog.showModal();
        dialog.focus();
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
    threadDispatcherId;
    goToThread() {
        this.isThreadButtonDisabled = true;
        if (this.request.IsAccountEqualOrderer__c == false && this.request.Orderer__c == this.userAccountId) {
            getThreadRequestId({ requestId: this.request.Id, type: 'HOT_BESTILLER-FORMIDLER' }).then((result) => {
                if (result != '') {
                    this.threadDispatcherId = result;
                    this.navigateToThread(this.threadDispatcherId);
                } else {
                    createThread({ recordId: this.request.Id, accountId: this.request.Orderer__c })
                        .then(async (result) => {
                            this.navigateToThread(result.Id);
                            await refreshApex(this.wiredgetWorkOrdersResult);
                            this.refresh(false);
                        })
                        .catch((error) => {
                            this.modalHeader = 'Noe gikk galt';
                            this.modalContent = 'Kunne ikke åpne samtale. Feilmelding: ' + error;
                            this.isCancelButton = false;
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
                        .then(async (result) => {
                            this.navigateToThread(result.Id);
                            await refreshApex(this.wiredgetWorkOrdersResult);
                            this.refresh(false);
                        })
                        .catch((error) => {
                            this.modalHeader = 'Noe gikk galt';
                            this.modalContent = 'Kunne ikke åpne samtale. Feilmelding: ' + error;
                            this.isCancelButton = false;
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
                        .then(async (result) => {
                            this.navigateToThread(result.Id);
                            await refreshApex(this.wiredgetWorkOrdersResult);
                            this.refresh(false);
                        })
                        .catch((error) => {
                            this.modalHeader = 'Noe gikk galt';
                            this.modalContent = 'Kunne ikke åpne samtale. Feilmelding: ' + error;
                            this.isCancelButton = false;
                            this.showModal();
                        });
                }
            });
        }
    }
    goToThreadInterpreter() {
        this.isInterpreterThreadButtonDisabled = true;
        getThreadInterpreterId({ workOrderId: this.workOrder.Id }).then((result) => {
            if (result != '') {
                this.workOrderThreadId = result;
                this.navigateToThread(this.workOrderThreadId);
            } else {
                createThread({ recordId: this.workOrder.Id, accountId: this.request.Account__c })
                    .then(async (result) => {
                        this.navigateToThread(result.Id);
                        await refreshApex(this.wiredgetWorkOrdersResult);
                        this.refresh(false);
                        this.workOrderThreadId = result.Id;
                    })
                    .catch((error) => {
                        this.modalHeader = 'Noe gikk galt';
                        this.modalContent = 'Kunne ikke åpne samtale. Feilmelding: ' + error;
                        this.isCancelButton = false;
                        this.isThreadButtonDisabled = false;
                        this.showModal();
                    });
            }
        });
    }
    goToThreadOrdererUser() {
        getThreadRequestId({ requestId: this.request.Id, type: 'HOT_BRUKER-BESTILLER' }).then((result) => {
            if (result != '') {
                this.threadDispatcherId = result;
                this.navigateToThread(this.threadDispatcherId);
            } else {
                createThreadOrdererUser({ recordId: this.request.Id, accountId: this.request.Account__c })
                    .then(async (result) => {
                        this.navigateToThread(result.Id);
                        await refreshApex(this.wiredgetWorkOrdersResult);
                        this.refresh(false);
                        this.workOrderThreadId = result.Id;
                    })
                    .catch((error) => {
                        this.modalHeader = 'Noe gikk galt';
                        this.modalContent = 'Kunne ikke åpne samtale. Feilmelding: ' + error;
                        this.isCancelButton = false;
                        this.isThreadButtonDisabled = false;
                        this.showModal();
                    });
            }
        });
    }
}
