import { LightningElement, wire, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getAcceptedServiceAppointments from '@salesforce/apex/HOT_TjenesteleverandorListController.getAcceptedServiceAppointments';
import icons from '@salesforce/resourceUrl/ikoner';

import { columns, mobileColumns } from './columns';
import { formatRecord } from 'c/datetimeFormatterNorwegianTime';
import { getDayOfWeek } from 'c/hot_commonUtils';

export default class Hot_tjenesteleverandorSaAcceptedList extends NavigationMixin(LightningElement) {
    @api recordId;

    exitCrossIcon = icons + '/Close/Close.svg';
    dataLoader = true;
    records = [];
    columns = [];
    error;

    showServiceAppointmentDetailsModal = false;
    serviceAppointment;
    selectedRecordId;

    datetimeFields = [
        { name: 'StartAndEndDate', type: 'datetimeinterval', start: 'EarliestStartTime', end: 'DueDate' },
        { name: 'HOT_DeadlineDate__c', type: 'date' },
        { name: 'HOT_ReleaseDate__c', type: 'date', newName: 'ReleaseDate' }
    ];

    connectedCallback() {
        this.columns = window.screen.width > 576 ? columns : mobileColumns;
    }

    get hasResult() {
        return !this.dataLoader && this.records.length > 0;
    }

    get noServiceAppointmentsResult() {
        return !this.dataLoader && this.records.length === 0;
    }

    @wire(getAcceptedServiceAppointments)
    wiredAcceptedServiceAppointments(result) {
        if (result.data) {
            this.records = result.data.map((record) => {
                const formattedRecord = formatRecord({ ...record }, this.datetimeFields);
                return {
                    ...formattedRecord,
                    HOT_ServiceAppointmentNumber__c: record.AppointmentNumber,
                    startAndEndDateWeekday: formattedRecord.StartAndEndDate,
                    weekday: getDayOfWeek(record.EarliestStartTime),
                    isOtherProvider: record.HOT_IsOtherEconomicProvicer__c ? 'Ja' : 'Nei'
                };
            });
            this.error = undefined;
            this.dataLoader = false;
        } else if (result.error) {
            this.error = result.error;
            this.records = [];
            this.dataLoader = false;
        }
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

    get status() {
        return this.serviceAppointment?.Status ?? '';
    }
}
