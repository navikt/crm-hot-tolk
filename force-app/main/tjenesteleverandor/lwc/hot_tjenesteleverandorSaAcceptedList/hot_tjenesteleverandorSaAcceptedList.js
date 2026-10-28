import { LightningElement, wire, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import getAcceptedServiceAppointments from '@salesforce/apex/HOT_TjenesteleverandorListController.getAcceptedServiceAppointments';
import releaseServiceAppointments from '@salesforce/apex/HOT_TjenesteleverandorReleaseService.releaseServiceAppointments';
import icons from '@salesforce/resourceUrl/ikoner';

import { columns, mobileColumns } from './columns';
import { formatRecord, formatDatetime } from 'c/datetimeFormatterNorwegianTime';
import { getDayOfWeek } from 'c/hot_commonUtils';
import { filterRecords, restoreFilters } from 'c/hot_tjenesteleverandorFilters';

const FILTER_STORAGE_KEY = 'tjenesteleverandorAcceptedFilters';

const LIST_REFRESH_KEY = 'tjenesteleverandorAcceptedListRefresh';

export default class Hot_tjenesteleverandorSaAcceptedList extends NavigationMixin(LightningElement) {
    @api recordId;

    exitCrossIcon = icons + '/Close/Close.svg';
    dataLoader = true;
    allRecords = [];
    records = [];
    filters = [];
    columns = [];
    error;
    checkedServiceAppointments = [];
    releaseAppointments = [];
    releaseTotal = 0;
    releasedCount = 0;
    showReleaseModal = false;
    showTransferModal = false;
    transferRecordIds = [];
    transferInputVariables = [];
    transferError;
    releaseFeedback;
    releaseError;
    isReleasing = false;
    pageScrollLock;

    showServiceAppointmentDetailsModal = false;
    serviceAppointment;
    selectedRecordId;
    wiredAcceptedAppointments;
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
        { name: 'HOT_ReleaseDate__c', type: 'date', newName: 'ReleaseDate' }
    ];

    connectedCallback() {
        this.filters = restoreFilters(FILTER_STORAGE_KEY);
        this.columns = window.screen.width > 576 ? columns : mobileColumns;
        // Keep page visibility listeners for refresh behavior and also emit filters for parent
        window.addEventListener('popstate', this.handlePageActivation);
        window.addEventListener('pageshow', this.handlePageActivation);
        document.addEventListener('visibilitychange', this.handleVisibilityChange);
        this.sendFilters();
        void this.refreshIfRequested();
    }

    disconnectedCallback() {
        this.unlockPageScroll();
        window.removeEventListener('popstate', this.handlePageActivation);
        window.removeEventListener('pageshow', this.handlePageActivation);
        document.removeEventListener('visibilitychange', this.handleVisibilityChange);
    }

    renderedCallback() {
        if (this.showReleaseModal || this.showTransferModal || this.showServiceAppointmentDetailsModal) {
            if (!this.pageScrollLock) {
                const element = document.scrollingElement;
                this.pageScrollLock = {
                    element,
                    overflow: element.style.getPropertyValue('overflow'),
                    priority: element.style.getPropertyPriority('overflow')
                };
                element.style.setProperty('overflow', 'hidden', 'important');
            }
        } else {
            this.unlockPageScroll();
        }
        const dialog = this.template.querySelector('[data-id="release-dialog"]');
        if (this.showReleaseModal && dialog && !dialog.open) {
            dialog.showModal();
        }
        const transferDialog = this.template.querySelector('[data-id="transfer-dialog"]');
        if (this.showTransferModal && transferDialog && !transferDialog.open) {
            transferDialog.showModal();
        }
    }

    unlockPageScroll() {
        if (this.pageScrollLock) {
            const { element, overflow, priority } = this.pageScrollLock;
            if (overflow) {
                element.style.setProperty('overflow', overflow, priority);
            } else {
                element.style.removeProperty('overflow');
            }
            this.pageScrollLock = undefined;
        }
    }

    get isReleaseDisabled() {
        return this.checkedServiceAppointments.length === 0 || this.showReleaseModal || this.showTransferModal;
    }

    get selectedAppointmentsLabel() {
        return `${this.checkedServiceAppointments.length} oppdrag valgt`;
    }

    get releaseHeading() {
        return `Frigi til tolker (${this.releaseTotal} oppdrag)`;
    }

    handleRowChecked(event) {
        this.checkedServiceAppointments = [...event.detail.checkedRows];
        this.releaseFeedback = undefined;
    }

    handleTransfer() {
        if (this.isReleaseDisabled) {
            return;
        }
        this.transferRecordIds = [...this.checkedServiceAppointments];
        this.transferInputVariables = [{ name: 'recordIds', type: 'String', value: this.transferRecordIds }];
        this.transferError = undefined;
        this.releaseFeedback = undefined;
        this.showTransferModal = true;
    }

    closeTransferModal() {
        this.showTransferModal = false;
        const dialog = this.template.querySelector('[data-id="transfer-dialog"]');
        if (dialog?.open) {
            dialog.close();
        }
    }

    handleTransferStatusChange(event) {
        const { status, outputVariables } = event.detail;
        if (status === 'ERROR') {
            this.transferError = 'Overføringen kunne ikke fullføres. Lukk vinduet og prøv igjen.';
            return;
        }
        if (status !== 'FINISHED' && status !== 'FINISHED_SCREEN') {
            return;
        }
        const transferred = outputVariables?.find((variable) => variable.name === 'transferred')?.value === true;
        this.closeTransferModal();
        if (!transferred) {
            return;
        }
        this.checkedServiceAppointments = [];
        this.template.querySelector('c-hot_freelance-common-table')?.unsetCheckboxes();
        this.releaseFeedback = {
            type: 'success',
            message: `${this.transferRecordIds.length} oppdrag overført til annen formidler.`
        };
        sessionStorage.setItem(LIST_REFRESH_KEY, String(Date.now()));
        void this.refreshIfRequested();
    }

    reconcileCheckedRows() {
        const visibleIds = new Set(this.records.map((record) => record.Id));
        this.checkedServiceAppointments = this.checkedServiceAppointments.filter((id) => visibleIds.has(id));
    }

    handleRelease() {
        if (this.isReleaseDisabled) {
            return;
        }
        const selectedIds = new Set(this.checkedServiceAppointments);
        this.releaseAppointments = this.records
            .filter((record) => selectedIds.has(record.Id))
            .map((record) => ({
                id: record.Id,
                appointmentNumber: record.AppointmentNumber,
                startTime: record.EarliestStartTime ? formatDatetime(record.EarliestStartTime) : '',
                endTime: record.DueDate ? formatDatetime(record.DueDate) : '',
                information: record.HOT_Information__c,
                deadline: record.releaseDeadline,
                subject: record.HOT_FreelanceSubject__c || record.Subject,
                subjectError: ''
            }));
        this.releaseTotal = this.releaseAppointments.length;
        this.releasedCount = 0;
        this.releaseFeedback = undefined;
        this.releaseError = undefined;
        this.showReleaseModal = true;
    }

    handleReleaseFieldChange(event) {
        const { recordId, field } = event.target.dataset;
        const value = event.detail;
        if (field === 'deadline') {
            event.target.sendErrorMessage(value ? '' : 'Feltet må fylles ut.');
        }
        this.releaseAppointments = this.releaseAppointments.map((appointment) =>
            appointment.id === recordId
                ? {
                      ...appointment,
                      [field]: value,
                      ...(field === 'subject' && value.trim() ? { subjectError: '' } : {})
                  }
                : appointment
        );
    }

    async handleSubmitRelease() {
        if (this.isReleasing) {
            return;
        }
        const fields = [...this.template.querySelectorAll('[data-release-field="deadline"]')];
        const invalidFields = fields.filter((field) => {
            const errorMessage = field.value ? '' : 'Feltet må fylles ut.';
            field.sendErrorMessage(errorMessage);
            return errorMessage !== '';
        });
        const invalidSubjects = this.releaseAppointments.filter((appointment) => !appointment.subject?.trim());
        if (invalidSubjects.length > 0) {
            const invalidSubjectIds = new Set(invalidSubjects.map((appointment) => appointment.id));
            this.releaseAppointments = this.releaseAppointments.map((appointment) =>
                invalidSubjectIds.has(appointment.id)
                    ? { ...appointment, subjectError: 'Feltet må fylles ut.' }
                    : appointment
            );
        }
        if (invalidFields.length > 0 || invalidSubjects.length > 0) {
            invalidFields[0]?.focus();
            return;
        }
        this.isReleasing = true;
        this.releaseError = undefined;
        try {
            await releaseServiceAppointments({
                appointments: this.releaseAppointments.map((appointment) => ({
                    Id: appointment.id,
                    HOT_DeadlineDate__c: appointment.deadline,
                    HOT_FreelanceSubject__c: appointment.subject
                }))
            });
            this.releasedCount = this.releaseAppointments.length;
            const releasedIds = new Set(this.releaseAppointments.map((appointment) => appointment.id));
            this.checkedServiceAppointments = this.checkedServiceAppointments.filter((id) => !releasedIds.has(id));
        } catch (error) {
            this.releaseError = error?.body?.message || 'Oppdragene kunne ikke frigis. Prøv igjen.';
        } finally {
            this.isReleasing = false;
        }
        if (!this.releaseError) {
            this.closeReleaseModal();
        }
    }

    handleReleaseCancel(event) {
        if (this.isReleasing) {
            event.preventDefault();
        }
    }

    dismissReleaseModal() {
        this.closeReleaseModal(false);
    }

    closeReleaseModal(showFeedback = true) {
        if (!this.showReleaseModal || this.isReleasing) {
            return;
        }
        this.showReleaseModal = false;
        const dialog = this.template.querySelector('[data-id="release-dialog"]');
        if (dialog?.open) {
            dialog.close();
        }
        const incompleteCount = this.releaseTotal - this.releasedCount;
        this.releaseFeedback = showFeedback
            ? {
                  type: incompleteCount > 0 ? 'warning' : 'success',
                  message:
                      `${this.releasedCount} oppdrag frigitt til frilanstolker.` +
                      (incompleteCount > 0
                          ? ` ${incompleteCount} oppdrag ble ikke fullført. Kontroller oppdragene før du prøver igjen.`
                          : '')
              }
            : undefined;
        this.releaseAppointments = [];
        if (this.releasedCount > 0 || showFeedback) {
            sessionStorage.setItem(LIST_REFRESH_KEY, String(Date.now()));
            void this.refreshIfRequested();
        }
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

    @wire(getAcceptedServiceAppointments)
    wiredAcceptedServiceAppointments(result) {
        this.wiredAcceptedAppointments = result;

        if (result.data) {
            this.allRecords = result.data.map((record) => {
                const formattedRecord = formatRecord({ ...record }, this.datetimeFields);
                return {
                    ...formattedRecord,
                    releaseDeadline:
                        record.HOT_DeadlineDate__c ||
                        (record.EarliestStartTime
                            ? new Intl.DateTimeFormat('sv-SE', {
                                  timeZone: 'Europe/Oslo',
                                  year: 'numeric',
                                  month: '2-digit',
                                  day: '2-digit'
                              }).format(new Date(record.EarliestStartTime))
                            : ''),
                    HOT_ServiceAppointmentNumber__c: record.AppointmentNumber,
                    startAndEndDateWeekday: formattedRecord.StartAndEndDate,
                    weekday: getDayOfWeek(record.EarliestStartTime),
                    isOtherProvider: record.HOT_IsOtherEconomicProvicer__c ? 'Ja' : 'Nei'
                };
            });
            this.records = filterRecords(this.allRecords, this.filters);
            this.reconcileCheckedRows();
            this.error = undefined;
            this.dataLoader = false;
            this.sendFilters();
            void this.refreshIfRequested();
        } else if (result.error) {
            this.error = result.error;
            this.allRecords = [];
            this.records = [];
            this.reconcileCheckedRows();
            this.dataLoader = false;
        }
    }

    // Keep both behaviours: refresh when signalled, and allow parent-driven filtering
    async refreshIfRequested() {
        const marker = sessionStorage.getItem(LIST_REFRESH_KEY);
        if (!marker || !this.wiredAcceptedAppointments || this.isRefreshPending) {
            return;
        }

        this.isRefreshPending = true;
        this.dataLoader = true;
        try {
            await refreshApex(this.wiredAcceptedAppointments);
            this.error = undefined;
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
            const dialog = this.template.querySelector('dialog[aria-label="Informasjon om oppdrag"]');
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
            attributes: {
                name: 'Oppdragsdetaljer__c'
            },
            state: {
                c__recordId: appointmentId
            }
        });
    }

    closeModal() {
        const dialog = this.template.querySelector('dialog[aria-label="Informasjon om oppdrag"]');
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
