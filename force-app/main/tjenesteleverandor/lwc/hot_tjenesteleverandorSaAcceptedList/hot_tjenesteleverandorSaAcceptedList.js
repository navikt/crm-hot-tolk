import { LightningElement, wire, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getAcceptedServiceAppointments from '@salesforce/apex/HOT_TjenesteleverandorListController.getAcceptedServiceAppointments';

import { columns, mobileColumns } from './columns';
import { formatRecord } from 'c/datetimeFormatterNorwegianTime';
import { getDayOfWeek } from 'c/hot_commonUtils';
import { refreshApex } from '@salesforce/apex';
import icons from '@salesforce/resourceUrl/ikoner';

export default class Hot_tjenesteleverandorSaAcceptedList extends NavigationMixin(LightningElement) {
    @api recordId;

    exitCrossIcon = icons + '/Close/Close.svg';
    dataLoader = true;

    records = [];
    columns = [];
    initialServiceAppointments = [];

    datetimeFields = [
        { name: 'StartAndEndDate', type: 'datetimeinterval', start: 'EarliestStartTime', end: 'DueDate' },
        { name: 'HOT_DeadlineDate__c', type: 'date' },
        { name: 'HOT_ReleaseDate__c', type: 'date', newName: 'ReleaseDate' }
    ];

    get hasResult() {
        return !this.dataLoader && this.records && this.records.length > 0;
    }

    get noServiceAppointmentsResult() {
        return !this.dataLoader && this.initialServiceAppointments.length === 0;
    }

    updateURL() {
        let baseURL =
            window.location.protocol + '//' + window.location.host + window.location.pathname + '?list=accepted';
        if (this.recordId) {
            baseURL += '&id=' + this.recordId;
        }
        window.history.pushState({ path: baseURL }, '', baseURL);
    }

    connectedCallback() {
        this.updateURL();
        this.setColumns();
    }

    setColumns() {
        if (window.screen.width > 576) {
            this.columns = columns;
        } else {
            this.columns = mobileColumns;
        }
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

        return `${day}.${month}.${year} ${hours}:${minutes}`;
    }

    sendRecords() {
        const eventToSend = new CustomEvent('sendrecords', { detail: this.initialServiceAppointments });
        this.dispatchEvent(eventToSend);
    }
    sendDetail() {
        const eventToSend = new CustomEvent('senddetail', { detail: this.isDetails });
        this.dispatchEvent(eventToSend);
    }

    refresh() {
        this.sendRecords();
    }

    noServiceAppointments = false;
    allAcceptedServiceAppointmentsWired = [];
    wiredAllAcceptedServiceAppointmentsResult;

    @wire(getAcceptedServiceAppointments)
    wiredAcceptedServiceAppointments(result) {
        if (result.data) {
            this.allAcceptedServiceAppointmentsWired = result.data.map((record) => ({
                ...record,
                startAndEndDateWeekday: this.formatDatetime(record.EarliestStartTime, record.DueDate),
                weekday: getDayOfWeek(record.EarliestStartTime),
                isOtherProvider: record.HOT_Request__r?.IsOtherEconomicProvicer__c ? 'Ja' : 'Nei'
            }));

            let tempRecords = [];
            for (let record of this.allAcceptedServiceAppointmentsWired) {
                tempRecords.push(formatRecord(Object.assign({}, record), this.datetimeFields));
            }

            this.records = tempRecords;
            this.initialServiceAppointments = tempRecords;
            this.dataLoader = false;
        } else if (result.error) {
            this.error = result.error;
            this.records = [];
            this.initialServiceAppointments = [];
            this.dataLoader = false;
            this.allAcceptedServiceAppointmentsWired = undefined;
        }
    }

    showServiceAppointmentDetailsModal = false;

    serviceAppointment;
    isDetails = false;
    goToRecordDetails(result) {
        this.serviceAppointment = undefined;
        let recordId = result.detail.Id;
        this.recordId = recordId;
        this.isDetails = !!this.recordId;
        for (let serviceAppointment of this.records) {
            if (recordId === serviceAppointment.Id) {
                this.serviceAppointment = serviceAppointment;
                this.serviceAppointment.weekday = getDayOfWeek(this.serviceAppointment.EarliestStartTime);
            }
        }
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
        if (!this.recordId) {
            return;
        }

        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'Oppdragsdetaljer__c'
            },
            state: {
                c__recordId: this.recordId
            }
        });
    }

    closeModal() {
        const dialog = this.template.querySelector('dialog');
        dialog.close();
        this.showServiceAppointmentDetailsModal = false;
    }

    get status() {
        return this.serviceAppointment?.Status ?? '';
    }
}
