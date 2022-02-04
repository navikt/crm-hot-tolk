import { LightningElement, track, wire } from 'lwc';
import getMyWorkOrdersAndRelatedRequest from '@salesforce/apex/HOT_WorkOrderListController.getMyWorkOrdersAndRelatedRequest';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { columns, mobileColumns, workOrderColumns, workOrderMobileColumns, iconByValue } from './columns';
import { defaultFilters } from './filters';
import getPersonAccount from '@salesforce/apex/HOT_Utility.getPersonAccount';
import STATUS from '@salesforce/schema/HOT_Request__c.Status__c';
import REQUEST_ID from '@salesforce/schema/HOT_Request__c.Id';
import FILE_CONSENT from '@salesforce/schema/HOT_Request__c.IsFileConsent__c';
import NOTIFY_DISPATCHER from '@salesforce/schema/HOT_Request__c.IsNotifyDispatcher__c';
import { refreshApex } from '@salesforce/apex';
import { updateRecord } from 'lightning/uiRecordApi';

export default class MineBestillingerWrapper extends NavigationMixin(LightningElement) {
    breadcrumbs = [
        {
            label: 'Tolketjenesten',
            href: ''
        },
        {
            label: 'Mine Bestillinger',
            href: 'mine-bestillinger'
        }
    ];

    @track filters = [];
    connectedCallback() {
        this.filters = defaultFilters();
        if (window.screen.width > 576) {
            this.columns = columns;
            this.workOrderColumns = workOrderColumns;
        } else {
            this.columns = mobileColumns;
            this.workOrderColumns = workOrderMobileColumns;
        }
        this.refresh();
    }
    isList = true;
    isRequestDetails = false;
    isWorkOrderDetails = false;
    @track urlStateParameters = { level: '', id: '' };
    @track columns;
    @track workOrderColumns;
    @track iconByValue = iconByValue;

    @track records = [];
    @track allRecords = [];
    wiredMyWorkOrdersNewResult;
    @wire(getMyWorkOrdersAndRelatedRequest)
    wiredMyWorkOrdersNew(result) {
        this.wiredMyWorkOrdersNewResult = result;
        if (result.data) {
            this.records = [...result.data];
            this.allRecords = [...result.data];
            this.refresh();
        }
    }
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference && this.isNavigatingAway === false) {
            this.urlStateParameters = { ...currentPageReference.state };
            this.refresh();
        }
    }

    @track request = { MeetingStreet__c: '', Subject__c: '' };
    @track workOrder = { HOT_AddressFormated__c: '', Subject: '' };
    @track workOrders = [];
    interpreter = 'Tolk';
    getRecords() {
        this.resetRequestAndWorkOrder();
        let recordId = this.urlStateParameters.id;
        console.log('recordId: ', recordId);
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
        this.isRequestEditButtonDisabled = this.request.Status__c === 'Åpen' ? false : true;
        this.isRequestCancelButtonDisabled = this.request.Status__c === 'Avlyst' ? true : false;
        this.isRequestAddFilesButtonDisabled = this.request.Status__c !== 'Avlyst' ? false : true;
        this.isWOEditButtonDisabled = this.workOrder.HOT_ExternalWorkOrderStatus__c === 'Åpen' ? false : true;
        this.isWOCancelButtonDisabled = this.workOrder.HOT_ExternalWorkOrderStatus__c === 'Avlyst' ? true : false;
        this.isWOAddFilesButtonDisabled = this.workOrder.HOT_ExternalWorkOrderStatus__c !== 'Avlyst' ? false : true;
    }

    getWorkOrders() {
        console.log('getWorkOrders');
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
        this.refresh();
    }

    editButtonLabel = 'Rediger';
    copyButtonLabel = 'Kopier';
    cancelButtonLabel = 'Avlys';
    setButtonLabels(level) {
        if (level === 'R') {
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
    setAddressFormat() {
        this.requestAddressToShow = this.request.IsScreenInterpreter__c
            ? 'Digitalt oppmøte'
            : this.request.MeetingStreet__c;
    }

    goBack() {
        console.log('goback');
        let currentLevel = this.urlStateParameters.level;
        let goThroughRequest = this.workOrder.HOT_Request__r.IsSerieoppdrag__c;
        if (currentLevel === 'WO' && goThroughRequest) {
            this.urlStateParameters.level = 'R';
        } else {
            this.urlStateParameters.id = undefined;
            this.urlStateParameters.level = undefined;
        }
        this.refresh();
    }

    refresh() {
        this.getRecords();
        this.updateURL();
        this.updateView();
        this.applyFilter({ detail: { filterArray: this.filters, setRecords: true } });
    }

    updateView() {
        this.isList = this.urlStateParameters.id === undefined;
        this.isRequestDetails = this.urlStateParameters.level === 'R';
        this.isWorkOrderDetails = this.urlStateParameters.level === 'WO';
        this.interpreter = this.workOrder?.HOT_Interpreters__c?.length > 1 ? 'Tolker' : 'Tolk';
        this.isGetAllFiles = this.request.Account__c === this.userRecord.AccountId ? true : false;
        this.setButtonLabels(this.urlStateParameters.level);
        this.setButtonStates();
        this.setDateFormats();
        this.setAddressFormat();
    }
    updateURL() {
        let refresh = window.location.protocol + '//' + window.location.host + window.location.pathname;
        if (this.urlStateParameters.id !== undefined && this.urlStateParameters.level !== undefined) {
            console.log('setting refresh');
            refresh += '?id=' + this.urlStateParameters.id + '&level=' + this.urlStateParameters.level;
        }
        console.log('refresh URL: ', refresh);
        window.history.pushState({ path: refresh }, '', refresh);
    }

    filteredRecordsLength = 0;
    applyFilter(event) {
        let setRecords = event.detail.setRecords;
        this.filters = event.detail.filterArray;

        let filteredRecords = [];
        console.log(this.allRecords.length);
        console.log(this.workOrders.length);
        console.log(this.request.Id);
        let records = this.isRequestDetails ? this.workOrders : this.allRecords;
        console.log(records.length);
        console.log('applyFilter this.filters: ', JSON.stringify(this.filters));
        for (let record of records) {
            let includeRecord = true;
            for (let filter of this.filters) {
                includeRecord *= filter.compare(record);
            }
            if (includeRecord) {
                filteredRecords.push(record);
            }
        }
        this.filteredRecordsLength = filteredRecords.length;

        if (setRecords) {
            console.log('setRecords: ', setRecords);
            this.records = filteredRecords;
        }
        console.log('filteredRecordsLength: ', this.filteredRecordsLength);
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
                        edit: true
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
                copy: true
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
            this.showModal();
        }
    }

    newRequest() {
        this.isNavigatingAway = true;
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                pageName: 'ny-bestilling'
            },
            state: {
                fromList: true
            }
        });
    }

    cancelAndRefreshApex() {
        const fields = {};
        fields[REQUEST_ID.fieldApiName] = this.request.Id;
        fields[STATUS.fieldApiName] = 'Avlyst';
        fields[NOTIFY_DISPATCHER.fieldApiName] = true;
        const recordInput = { fields };
        updateRecord(recordInput)
            .then(() => {
                refreshApex(this.allRecords);
                this.modalContent = 'Bestillingen er avlyst.';
                this.noCancelButton = true;
                this.showModal();
            })
            .catch(() => {
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
        this.template.querySelector('.loader').classList.add('hidden');
        this.modalHeader = 'Suksess!';
        // Only show pop-up modal if in add files window
        if (this.isAddFiles) {
            this.showModal();
        }
        this.template.querySelector('.ReactModal__Overlay').classList.add('hidden');
        this.template.querySelector('.skjema').classList.remove('hidden');
    }

    onUploadError(err) {
        this.template.querySelector('.loader').classList.add('hidden');
        this.modalHeader = 'Noe gikk galt';
        this.modalContent = 'Kunne ikke laste opp fil(er). Feilmelding: ' + err;
        this.showModal();
        this.template.querySelector('.ReactModal__Overlay').classList.add('hidden');
        this.template.querySelector('.skjema').classList.remove('hidden');
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
        if (event.detail === 'confirm' && this.modalContent === 'Bestillingen ble avlyst.') {
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
}
