import { api, track } from 'lwc';
import LightningModal from 'lightning/modal';
import ConfimationModal from 'c/hot_calendar_absence_modal_confirmation';
import getConflictsForTimePeriod from '@salesforce/apex/HOT_FreelanceAbsenceController.getConflictsForTimePeriod';
import deleteAbsence from '@salesforce/apex/HOT_FreelanceAbsenceController.deleteAbsence';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class Hot_Calendar_Absence_Modal extends LightningModal {
    @api event;
    isEdit;
    absenceType;
    absenceStart;
    absenceEnd;
    value = '';

    get options() {
        return [
            { label: 'Ferie', value: 'Ferie' },
            { label: 'Sykdom', value: 'Sykdom' },
            { label: 'Annet', value: 'Annet' }
        ];
    }

    connectedCallback() {
        if (this.event && this.event.extendedProps.recordId) {
            this.isEdit = true;
            this.absenceType = this.event.extendedProps.description;
            this.absenceStart = this.formatLocalDateTime(this.event.start);
            this.absenceEnd = this.formatLocalDateTime(this.event.end);
        }
    }
    async handleOkay() {
        // Fetch radio button value
        const radioGroup = this.refs.absenceTypeRadioGroup;
        const absenceType = radioGroup.value;

        // Fetch input field values
        const absenceStartDateTime = this.refs.absenceStartDateTimeInput.value;
        const absenceEndDateTime = this.refs.absenceEndDateTimeInput.value;
        const result = await getConflictsForTimePeriod({
            startTimeInMilliseconds: new Date(absenceStartDateTime).getTime(),
            endTimeInMilliseconds: new Date(absenceEndDateTime).getTime()
        });
        const confirmation = await ConfimationModal.open({
            content: result,
            absenceType: absenceType,
            absenceStartDateTime: absenceStartDateTime,
            absenceEndDateTime: absenceEndDateTime
        });
        if (confirmation) {
            if (this.isEdit) {
                this.handleDeleteAbsence(false);
                const event = new ShowToastEvent({
                    title: 'Fravær endret',
                    message: 'Fravær ble endret, og eventuelle konflikter ble løst',
                    variant: 'success'
                });
                this.dispatchEvent(event);
            } else {
                const event = new ShowToastEvent({
                    title: 'Fravær lagt til',
                    message: 'Fravær lagt til, og eventuelle konflikter ble løst',
                    variant: 'success'
                });
                this.dispatchEvent(event);
            }
            this.close(true);
        } else if (!confirmation) {
            console.log('not confirmation');
        }
    }
    async handleDeleteAbsence(giveDeleteToast) {
        deleteAbsence({ recordId: this.event.extendedProps.recordId }).then(() => {
            if (giveDeleteToast) {
                const event = new ShowToastEvent({
                    title: 'Fravær slettet',
                    message: 'Fraværet ble slettet vellykket',
                    variant: 'success'
                });
                this.dispatchEvent(event);
            }
            this.close(true);
        });
    }
    // Hjelper metode for å få dato i riktig tidsone for dateTime input felt
    formatLocalDateTime(date) {
        const year = date.getFullYear();
        const month = ('0' + (date.getMonth() + 1)).slice(-2); // Måneder er 0 indeksiert
        const day = ('0' + date.getDate()).slice(-2);
        const hours = ('0' + date.getHours()).slice(-2);
        const minutes = ('0' + date.getMinutes()).slice(-2);

        return `${year}-${month}-${day}T${hours}:${minutes}`;
    }
}
