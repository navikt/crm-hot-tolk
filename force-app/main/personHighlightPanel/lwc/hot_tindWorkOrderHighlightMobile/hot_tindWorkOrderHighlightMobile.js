import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

const SERVICE_APPOINTMENT_FIELDS = [
    'ServiceAppointment.HOT_WorkOrderLineItem__r.WorkOrder.WorkOrderNumber',
    'ServiceAppointment.HOT_WorkOrderLineItem__r.WorkOrder.Subject',
    'ServiceAppointment.HOT_WorkOrderLineItem__r.WorkOrder.StartDate',
    'ServiceAppointment.HOT_WorkOrderLineItem__r.WorkOrder.EndDate',
    'ServiceAppointment.HOT_WorkOrderLineItem__r.WorkOrder.Status',
    'ServiceAppointment.HOT_WorkOrderLineItem__r.WorkOrder.Account.Name'
];

const DATE_TIME_FORMATTER = new Intl.DateTimeFormat('nb-NO', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
});

export default class HotTindWorkOrderHighlightMobile extends LightningElement {
    @api recordId;

    serviceAppointmentRecord;
    error;

    @wire(getRecord, { recordId: '$recordId', fields: SERVICE_APPOINTMENT_FIELDS })
    wiredServiceAppointment({ data, error }) {
        if (data) {
            this.serviceAppointmentRecord = data;
            this.error = null;
        } else if (error) {
            this.serviceAppointmentRecord = null;
            this.error = error;
        }
    }

    getValue(record, path) {
        if (!record || !record.fields) {
            return null;
        }

        let current = record;
        for (const segment of path) {
            if (!current || !current.fields || !current.fields[segment]) {
                return null;
            }
            current = current.fields[segment];
            if (current && current.value !== undefined) {
                current = current.value;
            }
        }

        return typeof current === 'object' && current.value !== undefined ? current.value : current;
    }

    get isLoading() {
        return !this.serviceAppointmentRecord && !this.error;
    }

    get workOrderRecord() {
        return this.getValue(this.serviceAppointmentRecord, ['HOT_WorkOrderLineItem__r', 'WorkOrder']);
    }

    get hasInfo() {
        return !!this.workOrderRecord;
    }

    get hasNoData() {
        return !this.error && !this.isLoading && !this.hasInfo;
    }

    formatDateTime(value) {
        return value ? DATE_TIME_FORMATTER.format(new Date(value)) : '-';
    }

    get accountName() {
        return this.getValue(this.workOrderRecord, ['Account', 'Name']) || '-';
    }

    get workOrderNumber() {
        return this.getValue(this.workOrderRecord, ['WorkOrderNumber']) || '-';
    }

    get subject() {
        return this.getValue(this.workOrderRecord, ['Subject']) || '-';
    }

    get startTime() {
        return this.formatDateTime(this.getValue(this.workOrderRecord, ['StartDate']));
    }

    get endTime() {
        return this.formatDateTime(this.getValue(this.workOrderRecord, ['EndDate']));
    }

    get status() {
        const statusField = this.workOrderRecord?.fields?.Status;
        return statusField?.displayValue || statusField?.value || '-';
    }

    get detailsLine() {
        return [this.subject, this.startTime, this.endTime, this.status]
            .filter((value) => value && value !== '-')
            .join(' / ');
    }
}
