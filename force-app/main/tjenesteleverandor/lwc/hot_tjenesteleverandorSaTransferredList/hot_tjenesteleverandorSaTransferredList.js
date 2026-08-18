import { LightningElement, wire, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import getTransferredServiceAppointments from '@salesforce/apex/HOT_TjenesteleverandorListController.getTransferredServiceAppointments';
import canAcceptAppointments from '@salesforce/customPermission/HOT_AcceptTjenesteleverandorOppdrag';
import canDeclineAppointments from '@salesforce/customPermission/HOT_DeclineTjenesteleverandorOppdrag';
import icons from '@salesforce/resourceUrl/ikoner';

import { columns, mobileColumns, inDetailsColumns } from './columns';
import { formatRecord } from 'c/datetimeFormatterNorwegianTime';
import { getDayOfWeek } from 'c/hot_commonUtils';
import { filterRecords, restoreFilters } from 'c/hot_tjenesteleverandorFilters';

const CHECKED_ROWS_STORAGE_KEY = 'tjenesteleverandorTransferredCheckedRows';
const LIST_REFRESH_KEY = 'tjenesteleverandorTransferredListRefresh';
const ACCEPTED_LIST_REFRESH_KEY = 'tjenesteleverandorAcceptedListRefresh';
const FILTER_STORAGE_KEY = 'tjenesteleverandorTransferredFilters';

function createFeedback(type, message) {
    const success = type === 'success';
    return {
        message,
        className: success
            ? 'slds-notify slds-notify_alert slds-theme_success bulk-feedback'
            : 'slds-notify slds-notify_alert slds-alert_error bulk-feedback',
        role: success ? 'status' : 'alert',
        icon: success ? 'utility:success' : 'utility:error'
    };
}

export default class Hot_tjenesteleverandorSaTransferredList extends NavigationMixin(LightningElement) {
    @api recordId;

    exitCrossIcon = icons + '/Close/Close.svg';
    dataLoader = true;
    allRecords = [];
    records = [];
    filters = [];
    columns = [];
    inDetailsColumns = [];
    checkedServiceAppointments = [];
    showBulkReview = false;
    bulkReviewRecords = [];
    bulkAction = 'accept';
    bulkFeedback;
    error;

    showServiceAppointmentDetailsModal = false;
    serviceAppointment;
    selectedRecordId;
    isSeries = false;
    seriesRecords = [];

    wiredTransferredAppointments;
    isRefreshPending = false;

    handlePageActivation = () => {
        void this.refreshIfRequested();
    };

    handleVisibilityChange = () => {
        if (document.visibilityState === 'visible') {
            void this.refreshIfRequested();
        }
    };

    datetimeFields = [
        { name: 'StartAndEndDate', type: 'datetimeinterval', start: 'EarliestStartTime', end: 'DueDate' },
        { name: 'HOT_DeadlineDate__c', type: 'date' },
        {
            name: 'HOT_TjenesteleverandorDeadline__c',
            type: 'datetime',
            newName: 'TjenesteleverandorDeadline'
        },
        { name: 'HOT_TjenesteleverandorTransferDate__c', type: 'datetime' },
        { name: 'HOT_ReleaseDate__c', type: 'date', newName: 'ReleaseDate' }
    ];

    connectedCallback() {
        this.restoreCheckedRows();
        this.filters = restoreFilters(FILTER_STORAGE_KEY);
        // ensure columns and listeners, and notify parent about filters
        this.setColumns();
        window.addEventListener('popstate', this.handlePageActivation);
        window.addEventListener('pageshow', this.handlePageActivation);
        document.addEventListener('visibilitychange', this.handleVisibilityChange);
        this.sendFilters();
        void this.refreshIfRequested();
    }

    disconnectedCallback() {
        this.persistCheckedRows();
        window.removeEventListener('popstate', this.handlePageActivation);
        window.removeEventListener('pageshow', this.handlePageActivation);
        document.removeEventListener('visibilitychange', this.handleVisibilityChange);
    }

    setColumns() {
        this.columns = window.screen.width > 576 ? columns : mobileColumns;
        this.inDetailsColumns = inDetailsColumns;
    }

    restoreCheckedRows() {
        const storedRows = sessionStorage.getItem(CHECKED_ROWS_STORAGE_KEY);
        if (!storedRows) {
            return;
        }

        try {
            const checkedRows = JSON.parse(storedRows);
            this.checkedServiceAppointments = Array.isArray(checkedRows) ? checkedRows : [];
        } catch {
            this.checkedServiceAppointments = [];
            sessionStorage.removeItem(CHECKED_ROWS_STORAGE_KEY);
        }
    }

    persistCheckedRows() {
        sessionStorage.setItem(CHECKED_ROWS_STORAGE_KEY, JSON.stringify(this.checkedServiceAppointments));
    }

    get hasResult() {
        return !this.dataLoader && this.records.length > 0;
    }

    get noServiceAppointmentsResult() {
        return !this.dataLoader && this.allRecords.length === 0;
    }

    get noFilteredRecordsResult() {
        return !this.dataLoader && this.allRecords.length > 0 && this.records.length === 0;
    }

    get selectedAppointmentCount() {
        return this.checkedServiceAppointments.length;
    }

    get selectedAppointmentsLabel() {
        return `${this.selectedAppointmentCount} oppdrag valgt`;
    }

    get canShowBulkAcceptance() {
        return Boolean(canAcceptAppointments);
    }

    get canShowBulkDecline() {
        return Boolean(canDeclineAppointments);
    }

    get isBulkResponseDisabled() {
        return this.selectedAppointmentCount === 0;
    }

    get bulkAcceptButtonLabel() {
        return this.selectedAppointmentCount === 0
            ? 'Aksepter valgte oppdrag'
            : `Aksepter valgte (${this.selectedAppointmentCount})`;
    }

    get bulkAcceptButtonAriaLabel() {
        return this.selectedAppointmentCount === 0
            ? 'Velg oppdrag før du aksepterer'
            : `Gå til bekreftelse for ${this.selectedAppointmentCount} valgte oppdrag`;
    }

    get bulkDeclineButtonLabel() {
        return this.selectedAppointmentCount === 0
            ? 'Avslå valgte oppdrag'
            : `Avslå valgte (${this.selectedAppointmentCount})`;
    }

    get bulkDeclineButtonAriaLabel() {
        return this.selectedAppointmentCount === 0
            ? 'Velg oppdrag før du avslår'
            : `Gå til bekreftelse for å avslå ${this.selectedAppointmentCount} valgte oppdrag`;
    }

    @wire(getTransferredServiceAppointments)
    wiredTransferredServiceAppointments(result) {
        this.wiredTransferredAppointments = result;

        if (result.data) {
            this.allRecords = result.data.map((record) => {
                const formattedRecord = formatRecord({ ...record }, this.datetimeFields);
                return {
                    ...formattedRecord,
                    HOT_ServiceAppointmentNumber__c: record.AppointmentNumber,
                    startAndEndDateWeekday: formattedRecord.StartAndEndDate,
                    weekday: getDayOfWeek(record.EarliestStartTime),
                    isOtherProvider: record.HOT_IsOtherEconomicProvicer__c ? 'Ja' : 'Nei'
                };
            });
            this.applyCurrentFilters();
            this.error = undefined;
            this.dataLoader = false;
            this.sendFilters();
            void this.refreshIfRequested();
        } else if (result.error) {
            this.error = result.error;
            this.allRecords = [];
            this.records = [];
            this.dataLoader = false;
        }
    }

    // Keep both behaviours: on-demand refresh and parent-driven filtering
    async refreshIfRequested() {
        const marker = sessionStorage.getItem(LIST_REFRESH_KEY);
        if (!marker || !this.wiredTransferredAppointments || this.isRefreshPending) {
            return;
        }

        this.isRefreshPending = true;
        this.dataLoader = true;
        try {
            await refreshApex(this.wiredTransferredAppointments);
            if (sessionStorage.getItem(LIST_REFRESH_KEY) === marker) {
                sessionStorage.removeItem(LIST_REFRESH_KEY);
            }
        } catch (error) {
            this.error = error;
            this.records = [];
        } finally {
            this.isRefreshPending = false;
            this.dataLoader = false;
        }
    }

    sendFilters() {
        this.dispatchEvent(new CustomEvent('sendfilters', { detail: this.filters }));
    }

    @api
    applyFilter(event) {
        if (Array.isArray(event.detail?.filterArray)) {
            this.filters = event.detail.filterArray;
            sessionStorage.setItem(FILTER_STORAGE_KEY, JSON.stringify(this.filters));
        }

        const filteredRecords = filterRecords(this.allRecords, this.filters);
        if (event.detail?.setRecords) {
            this.records = filteredRecords;
            this.reconcileCheckedRows();
        }
        return filteredRecords.length;
    }

    applyCurrentFilters() {
        this.records = filterRecords(this.allRecords, this.filters);
        this.reconcileCheckedRows();
    }

    reconcileCheckedRows() {
        const visibleRecordIds = new Set(this.records.map((record) => record.Id));
        this.checkedServiceAppointments = this.checkedServiceAppointments.filter((recordId) =>
            visibleRecordIds.has(recordId)
        );
        this.persistCheckedRows();
    }

    goToRecordDetails(event) {
        const selectedRecord = this.records.find((record) => record.Id === event.detail.Id);
        if (!selectedRecord) {
            return;
        }

        this.selectedRecordId = selectedRecord.Id;
        this.serviceAppointment = {
            ...selectedRecord,
            weekday: getDayOfWeek(selectedRecord.EarliestStartTime)
        };
        const isSeriesAppointment = selectedRecord.HOT_IsSerieoppdrag__c === true;
        this.seriesRecords =
            isSeriesAppointment && selectedRecord.HOT_Request__c
                ? this.records.filter(
                      (record) =>
                          record.HOT_IsSerieoppdrag__c === true &&
                          record.HOT_Request__c === selectedRecord.HOT_Request__c
                  )
                : [selectedRecord];
        this.isSeries = isSeriesAppointment && this.seriesRecords.length > 1;
        this.showServiceAppointmentDetails();
    }

    showServiceAppointmentDetails() {
        this.showServiceAppointmentDetailsModal = true;
        setTimeout(() => {
            const dialog = this.template.querySelector('dialog');
            if (dialog) {
                dialog.showModal();
                dialog.focus();
            }
        }, 0);
    }

    handleRowChecked(event) {
        this.checkedServiceAppointments = [...event.detail.checkedRows];
        this.bulkFeedback = undefined;
        this.persistCheckedRows();
    }

    handleStartBulkAcceptReview() {
        this.startBulkReview('accept');
    }

    handleStartBulkDeclineReview() {
        this.startBulkReview('decline');
    }

    startBulkReview(action) {
        if (this.isBulkResponseDisabled) {
            return;
        }

        this.bulkAction = action;
        const checkedIds = new Set(this.checkedServiceAppointments);
        this.bulkReviewRecords = this.records.filter((record) => checkedIds.has(record.Id));
        this.showBulkReview = this.bulkReviewRecords.length > 0;
    }

    handleCancelBulkReview() {
        this.showBulkReview = false;
        this.bulkReviewRecords = [];
    }

    async handleBulkResponseComplete(event) {
        const results = event.detail?.results || [];
        const action = event.detail?.action || this.bulkAction;
        const completedAction = action === 'decline' ? 'avslått' : 'akseptert';
        const failedAction = action === 'decline' ? 'avslås' : 'aksepteres';
        const succeeded = results.filter((result) => result.success);
        const failed = results.filter((result) => !result.success);

        this.showBulkReview = false;
        this.bulkReviewRecords = [];
        this.checkedServiceAppointments = failed.map((result) => result.recordId);
        this.persistCheckedRows();

        if (action === 'accept' && succeeded.length > 0) {
            sessionStorage.setItem(ACCEPTED_LIST_REFRESH_KEY, String(Date.now()));
        }

        if (results.length === 0) {
            this.bulkFeedback = createFeedback('error', `Ingen av de valgte oppdragene kunne ${failedAction}.`);
        } else if (failed.length === 0) {
            this.bulkFeedback = createFeedback('success', `${succeeded.length} oppdrag ble ${completedAction}.`);
        } else if (succeeded.length > 0) {
            this.bulkFeedback = createFeedback(
                'error',
                `${succeeded.length} oppdrag ble ${completedAction}. ${failed.length} kunne ikke ${failedAction} og er fortsatt valgt.`
            );
        } else {
            this.bulkFeedback = createFeedback(
                'error',
                failed[0]?.message || `Ingen av de valgte oppdragene kunne ${failedAction}.`
            );
        }

        if (this.wiredTransferredAppointments) {
            await refreshApex(this.wiredTransferredAppointments);
        }
    }

    handleViewMoreInfo() {
        const appointmentId = this.selectedRecordId || this.recordId;
        if (!appointmentId) {
            return;
        }

        this.closeModal();
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'Oppdragsdetaljer__c'
            },
            state: {
                c__recordId: appointmentId
            }
        });
    }

    closeModal() {
        const dialog = this.template.querySelector('dialog');
        if (dialog?.open) {
            dialog.close();
        }
        this.showServiceAppointmentDetailsModal = false;
        this.serviceAppointment = undefined;
        this.selectedRecordId = undefined;
        this.isSeries = false;
        this.seriesRecords = [];
    }
}
