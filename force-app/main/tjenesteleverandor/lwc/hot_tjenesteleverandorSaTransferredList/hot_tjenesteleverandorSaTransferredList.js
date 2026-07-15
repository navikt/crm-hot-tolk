import { LightningElement, wire, api } from 'lwc';
import getTransferredServiceAppointments from '@salesforce/apex/HOT_TjenesteleverandorListController.getTransferredServiceAppointments';
import { columns, mobileColumns, inDetailsColumns } from './columns';
import { formatRecord } from 'c/datetimeFormatterNorwegianTime';
import { getDayOfWeek } from 'c/hot_commonUtils';
import { refreshApex } from '@salesforce/apex';
import icons from '@salesforce/resourceUrl/ikoner';

export default class Hot_tjenesteleverandorSaTransferredList extends LightningElement {
    @api recordId;

    exitCrossIcon = icons + '/Close/Close.svg';
    dataLoader = true;

    records = [];
    columns = [];
    inDetailsColumns = [];
    initialServiceAppointments = [];
    checkedServiceAppointments = [];

    datetimeFields = [
        { name: 'StartAndEndDate', type: 'datetimeinterval', start: 'EarliestStartTime', end: 'DueDate' },
        { name: 'HOT_DeadlineDate__c', type: 'date' },
        { name: 'HOT_ReleaseDate__c', type: 'date', newName: 'ReleaseDate' }
    ];

    updateURL() {
        let baseURL =
            window.location.protocol + '//' + window.location.host + window.location.pathname + '?list=transferred';
        if (this.recordId) {
            baseURL += '&id=' + this.recordId;
        }
        window.history.pushState({ path: baseURL }, '', baseURL);
    }

    refresh() {
        this.sendRecords();
        this.sendCheckedRows();
    }

    connectedCallback() {
        this.updateURL();

        if (sessionStorage.getItem('checkedrowsSavedForRefresh')) {
            this.checkedServiceAppointments = JSON.parse(sessionStorage.getItem('checkedrowsSavedForRefresh'));
            sessionStorage.removeItem('checkedrowsSavedForRefresh');
        }
        this.setColumns();
        refreshApex(this.wiredAllTransferredServiceAppointmentsResult);
    }

    setColumns() {
        if (window.screen.width > 576) {
            this.columns = columns;
            this.inDetailsColumns = inDetailsColumns;
        } else {
            this.columns = mobileColumns;
            this.inDetailsColumns = inDetailsColumns;
        }
    }

    get hasResult() {
        return !this.dataLoader && this.records && this.records.length > 0;
    }

    get noServiceAppointmentsResult() {
        return !this.dataLoader && this.initialServiceAppointments.length === 0;
    }

    formatDatetime(Start, DueDate) {
        const datetimeStart = new Date(Start);
        const dayStart = datetimeStart.getDate().toString().padStart(2, '0');
        const monthStart = (datetimeStart.getMonth() + 1).toString().padStart(2, '0');
        const yearStart = datetimeStart.getFullYear();
        const hoursStart = datetimeStart.getHours().toString().padStart(2, '0');
        const minutesStart = datetimeStart.getMinutes().toString().padStart(2, '0');

        const datetimeEnd = new Date(DueDate);
        const hoursEnd = datetimeEnd.getHours().toString().padStart(2, '0');
        const minutesEnd = datetimeEnd.getMinutes().toString().padStart(2, '0');

        return `${dayStart}.${monthStart}.${yearStart} ${hoursStart}:${minutesStart} - ${hoursEnd}:${minutesEnd}`;
    }

    formatSingleDatetime(value) {
        if (!value) {
            return '';
        }

        const datetime = new Date(value);
        const day = datetime.getDate().toString().padStart(2, '0');
        const month = (datetime.getMonth() + 1).toString().padStart(2, '0');
        const year = datetime.getFullYear();
        const hours = datetime.getHours().toString().padStart(2, '0');
        const minutes = datetime.getMinutes().toString().padStart(2, '0');

        return `${day}.${month}.${year}, ${hours}:${minutes}`;
    }

    sendRecords() {
        const eventToSend = new CustomEvent('sendrecords', { detail: this.initialServiceAppointments });
        this.dispatchEvent(eventToSend);
    }
    sendDetail() {
        const eventToSend = new CustomEvent('senddetail', { detail: this.isDetails });
        this.dispatchEvent(eventToSend);
    }
    sendCheckedRows() {
        const eventToSend = new CustomEvent('sendcheckedrows', { detail: this.checkedServiceAppointments });
        this.dispatchEvent(eventToSend);
    }
    setCheckedRowsOnRefresh() {
        if (sessionStorage.getItem('checkedrows') && !this.isDetails) {
            this.checkedServiceAppointments = JSON.parse(sessionStorage.getItem('checkedrows')) || [];
            sessionStorage.removeItem('checkedrows');
        }
        this.sendCheckedRows();
    }
    disconnectedCallback() {
        sessionStorage.setItem('checkedrows', JSON.stringify(this.checkedServiceAppointments || []));
    }
    renderedCallback() {
        this.setCheckedRowsOnRefresh();
        sessionStorage.setItem('checkedrowsSavedForRefresh', JSON.stringify(this.checkedServiceAppointments));
    }

    noServiceAppointments = false;
    allTransferredServiceAppointmentsWired = [];
    wiredAllTransferredServiceAppointmentsResult;
    @wire(getTransferredServiceAppointments)
    wiredTransferredServiceAppointments(result) {
        if (result.data) {
            this.allTransferredServiceAppointmentsWired = result.data.map((record) => ({
                ...record,
                startAndEndDateWeekday: this.formatDatetime(record.EarliestStartTime, record.DueDate),
                weekday: getDayOfWeek(record.EarliestStartTime),
                isOtherProvider: record.HOT_Request__r?.IsOtherEconomicProvicer__c ? 'Ja' : 'Nei',
                HOT_TjenesteleverandorTransferDate__c: this.formatSingleDatetime(
                    record.HOT_TjenesteleverandorTransferDate__c
                )
            }));

            let tempRecords = [];
            for (let record of this.allTransferredServiceAppointmentsWired) {
                tempRecords.push(formatRecord(Object.assign({}, record), this.datetimeFields));
            }

            this.records = tempRecords;
            this.initialServiceAppointments = [...this.records];
            this.dataLoader = false;
        } else if (result.error) {
            this.error = result.error;
            this.records = [];
            this.initialServiceAppointments = [];
            this.dataLoader = false;
            this.allTransferredServiceAppointmentsWired = undefined;
        }
    }

    showServiceAppointmentDetailsModal = false;

    serviceAppointment;
    isDetails = false;
    isSeries = false;
    seriesRecords = [];
    goToRecordDetails(result) {
        this.serviceAppointment = undefined;
        this.seriesRecords = [];
        let recordId = result.detail.Id;
        this.recordId = recordId;
        this.isDetails = !!this.recordId;
        for (let serviceAppointment of this.records) {
            if (recordId === serviceAppointment.Id) {
                this.serviceAppointment = serviceAppointment;
                this.isSeries = this.serviceAppointment.HOT_IsSerieoppdrag__c;
                this.serviceAppointment.weekday = getDayOfWeek(this.serviceAppointment.EarliestStartTime);
            }
        }
        for (let serviceAppointment of this.records) {
            if (this.serviceAppointment?.HOT_Request__c === serviceAppointment?.HOT_Request__c) {
                this.seriesRecords.push(serviceAppointment);
            }
        }
        this.isSeries = this.seriesRecords.length <= 1 ? false : true;
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
        this.checkedServiceAppointments = event.detail.checkedRows;
        this.sendCheckedRows();
    }

    closeModal() {
        const dialog = this.template.querySelector('dialog');
        dialog.close();
        this.showServiceAppointmentDetailsModal = false;
    }
}
