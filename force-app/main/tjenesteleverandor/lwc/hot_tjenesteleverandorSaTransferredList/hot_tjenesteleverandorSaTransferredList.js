import { LightningElement, wire, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import getTransferredServiceAppointments from '@salesforce/apex/HOT_TjenesteleverandorListController.getTransferredServiceAppointments';
import canAcceptAppointments from '@salesforce/customPermission/HOT_AcceptTjenesteleverandorOppdrag';
import icons from '@salesforce/resourceUrl/ikoner';

import { columns, mobileColumns, inDetailsColumns } from './columns';
import { formatRecord } from 'c/datetimeFormatterNorwegianTime';
import { getDayOfWeek } from 'c/hot_commonUtils';
import { filterRecords, restoreFilters } from 'c/hot_tjenesteleverandorFilters';

const CHECKED_ROWS_STORAGE_KEY = 'tjenesteleverandorTransferredCheckedRows';
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
    bulkFeedback;
    error;

    showServiceAppointmentDetailsModal = false;
    serviceAppointment;
    selectedRecordId;
    isSeries = false;
    seriesRecords = [];

    wiredTransferredAppointments;

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
        this.setColumns();
        this.sendFilters();
    }

    disconnectedCallback() {
        this.persistCheckedRows();
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

    get isBulkAcceptDisabled() {
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
        } else if (result.error) {
            this.error = result.error;
            this.allRecords = [];
            this.records = [];
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
        this.seriesRecords = selectedRecord.HOT_Request__c
            ? this.records.filter((record) => record.HOT_Request__c === selectedRecord.HOT_Request__c)
            : [selectedRecord];
        this.isSeries = this.seriesRecords.length > 1;
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

    handleStartBulkReview() {
        if (this.isBulkAcceptDisabled) {
            return;
        }

        const checkedIds = new Set(this.checkedServiceAppointments);
        this.bulkReviewRecords = this.records.filter((record) => checkedIds.has(record.Id));
        this.showBulkReview = this.bulkReviewRecords.length > 0;
    }

    handleCancelBulkReview() {
        this.showBulkReview = false;
        this.bulkReviewRecords = [];
    }

    async handleBulkAcceptComplete(event) {
        const results = event.detail?.results || [];
        const succeeded = results.filter((result) => result.success);
        const failed = results.filter((result) => !result.success);

        this.showBulkReview = false;
        this.bulkReviewRecords = [];
        this.checkedServiceAppointments = failed.map((result) => result.recordId);
        this.persistCheckedRows();

        if (results.length === 0) {
            this.bulkFeedback = createFeedback('error', 'Ingen av de valgte oppdragene kunne aksepteres.');
        } else if (failed.length === 0) {
            this.bulkFeedback = createFeedback('success', `${succeeded.length} oppdrag ble akseptert.`);
        } else if (succeeded.length > 0) {
            this.bulkFeedback = createFeedback(
                'error',
                `${succeeded.length} oppdrag ble akseptert. ${failed.length} kunne ikke aksepteres og er fortsatt valgt.`
            );
        } else {
            this.bulkFeedback = createFeedback(
                'error',
                failed[0]?.message || 'Ingen av de valgte oppdragene kunne aksepteres.'
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
    }
}
