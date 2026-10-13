import { LightningElement, wire, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import getFinishedServiceAppointments from '@salesforce/apex/HOT_TjenesteleverandorListController.getFinishedServiceAppointments';
import icons from '@salesforce/resourceUrl/ikoner';
import { columns, mobileColumns } from './columns';
import { formatRecord } from 'c/datetimeFormatterNorwegianTime';
import { getDayOfWeek } from 'c/hot_commonUtils';
import { filterRecords, restoreFilters } from 'c/hot_tjenesteleverandorFilters';

const FILTER_STORAGE_KEY = 'tjenesteleverandorFinishedFilters';

export default class Hot_tjenesteleverandorSaFinishedList extends NavigationMixin(LightningElement) {
    @api recordId;

    exitCrossIcon = icons + '/Close/Close.svg';
    dataLoader = true;
    allRecords = [];
    records = [];
    filters = [];
    columns = [];
    error;
    hasRefreshedEmptyResult = false;
    hasVerifiedEmptyResult = false;
    isEmptyResultRefreshPending = false;
    showServiceAppointmentDetailsModal = false;
    serviceAppointment;
    selectedRecordId;

    datetimeFields = [
        { name: 'StartAndEndDate', type: 'datetimeinterval', start: 'EarliestStartTime', end: 'DueDate' },
        { name: 'HOT_DeadlineDate__c', type: 'date' },
        { name: 'HOT_ReleaseDate__c', type: 'date', newName: 'ReleaseDate' }
    ];

    connectedCallback() {
        this.filters = restoreFilters(FILTER_STORAGE_KEY);
        this.columns = window.screen.width > 576 ? columns : mobileColumns;
        this.sendFilters();
    }

    get hasResult() {
        return !this.dataLoader && this.records.length > 0;
    }

    get noServiceAppointmentsResult() {
        return !this.dataLoader && this.hasVerifiedEmptyResult && this.allRecords.length === 0;
    }

    get noFilteredRecordsResult() {
        return !this.dataLoader && this.allRecords.length > 0 && this.records.length === 0;
    }

    @wire(getFinishedServiceAppointments)
    wiredFinishedServiceAppointments(result) {
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
            this.records = filterRecords(this.allRecords, this.filters);
            this.error = undefined;
            this.sendFilters();

            if (this.allRecords.length === 0 && !this.hasRefreshedEmptyResult) {
                this.hasRefreshedEmptyResult = true;
                this.isEmptyResultRefreshPending = true;
                void this.refreshEmptyResult(result);
                return;
            }

            if (this.allRecords.length > 0) {
                this.hasVerifiedEmptyResult = false;
                this.dataLoader = false;
            } else if (!this.isEmptyResultRefreshPending) {
                this.hasVerifiedEmptyResult = true;
                this.dataLoader = false;
            }
        } else if (result.error) {
            this.error = result.error;
            this.allRecords = [];
            this.records = [];
            this.dataLoader = false;
        }
    }

    async refreshEmptyResult(result) {
        try {
            await refreshApex(result);
            this.hasVerifiedEmptyResult = this.allRecords.length === 0;
        } catch (error) {
            this.error = error;
        } finally {
            this.isEmptyResultRefreshPending = false;
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
        }
        return filteredRecords.length;
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

    handleViewMoreInfo() {
        const appointmentId = this.selectedRecordId || this.recordId;
        if (!appointmentId) {
            return;
        }
        this.closeModal();
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: { name: 'Oppdragsdetaljer__c' },
            state: { c__recordId: appointmentId }
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
    }

    get status() {
        return this.serviceAppointment?.Status ?? '';
    }
}
