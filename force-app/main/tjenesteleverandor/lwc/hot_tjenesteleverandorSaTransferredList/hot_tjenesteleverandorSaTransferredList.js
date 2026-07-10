import { LightningElement, wire } from 'lwc';
import getTransferredServiceAppointments from '@salesforce/apex/HOT_TjenesteleverandorListController.getTransferredServiceAppointments';
import { columns, mobileColumns } from './columns';
import { formatRecord } from 'c/datetimeFormatterNorwegianTime';
import { getDayOfWeek } from 'c/hot_commonUtils';

export default class Hot_tjenesteleverandorSaTransferredList extends LightningElement {
    columns = [];
    dataLoader = true;
    records = [];
    initialServiceAppointments = [];

    datetimeFields = [
        { name: 'StartAndEndDate', type: 'datetimeinterval', start: 'EarliestStartTime', end: 'DueDate' }
    ];

    connectedCallback() {
        this.setColumns();
    }

    setColumns() {
        if (window.screen.width > 576) {
            this.columns = columns;
        } else {
            this.columns = mobileColumns;
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

        return `${day}.${month}.${year} ${hours}:${minutes}`;
    }

    @wire(getTransferredServiceAppointments)
    wiredTransferredServiceAppointments(result) {
        if (result.data) {
            const mappedRecords = result.data.map((record) => ({
                ...record,
                startAndEndDateWeekday: this.formatDatetime(record.EarliestStartTime, record.DueDate),
                weekday: getDayOfWeek(record.EarliestStartTime),
                HOT_TjenesteleverandorTransferDate__c: this.formatSingleDatetime(
                    record.HOT_TjenesteleverandorTransferDate__c
                )
            }));

            let tempRecords = [];
            for (let record of mappedRecords) {
                tempRecords.push(formatRecord(Object.assign({}, record), this.datetimeFields));
            }

            this.records = tempRecords;
            this.initialServiceAppointments = [...tempRecords];
            this.dataLoader = false;
        } else if (result.error) {
            this.records = [];
            this.initialServiceAppointments = [];
            this.dataLoader = false;
        }
    }
}
