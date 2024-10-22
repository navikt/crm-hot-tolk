import { api, track } from 'lwc';
import LightningModal from 'lightning/modal';
import ConfimationModal from 'c/hot_calendar_absence_modal_confirmation';
import DeleteConfimationModal from 'c/hot_calendar_absence_modal_confirmation_delete';
import getConflictsForTimePeriod from '@salesforce/apex/HOT_FreelanceAbsenceController.getConflictsForTimePeriod';
import createAbsenceAndResolveConflicts from '@salesforce/apex/HOT_FreelanceAbsenceController.createAbsenceAndResolveConflicts';
import deleteAbsence from '@salesforce/apex/HOT_FreelanceAbsenceController.deleteAbsence';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class Hot_Calendar_Absence_Modal extends LightningModal {
    @api event;
    isEdit;
    absenceType;
    absenceStart;
    absenceEnd;
    value = '';
    isLoading = false;
    headerText;
    startTimeInputLabel;
    endTImeInputLabel;
    registerButtonText;

    get options() {
        return [
            { label: 'Ferie', value: 'Vacation' },
            { label: 'Sykdom', value: 'Medical' },
            { label: 'Annet', value: 'Other' }
        ];
    }

    connectedCallback() {
        if (this.event && this.event.extendedProps.recordId) {
            this.isEdit = true;
            switch (this.event.extendedProps.description) {
                case 'Ferie':
                    this.absenceType = 'Vacation';
                    break;
                case 'Sykdom':
                    this.absenceType = 'Medical';
                    break;
                case 'Annet':
                    this.absenceType = 'Other';
                    break;
                default:
                    this.absenceType = 'Other';
                    break;
            }
            this.absenceStart = this.formatLocalDateTime(this.event.start);
            this.absenceEnd = this.formatLocalDateTime(this.event.end);
        } else {
            const now = new Date();
            const startTime = new Date(Date.now() + (60 - now.getMinutes()) * 60000);
            this.absenceStart = this.formatLocalDateTime(startTime);
            this.absenceEnd = this.formatLocalDateTime(new Date(startTime.getTime() + 86400000));
        }

        this.headerText = this.isEdit ? 'Endre/Slett fravær' : 'Registrer nytt fravær';
        this.startTimeInputLabel = `Legg inn${this.isEdit ? ' ny' : ''} startdato/tid`;
        this.endTimeInputLabel = `Legg inn${this.isEdit ? ' ny' : ''} sluttdato/tid`;
        this.registerButtonText = this.isEdit ? 'Endre' : 'Registrer';
    }

    validateAbsenceType(absenceType) {
        return ['Vacation', 'Other', 'Medical'].includes(absenceType);
    }

    async handleOkay() {
        // Fetch radio button value
        let validInputs = true;
        const radioGroup = this.refs.absenceTypeRadioGroup;
        const absenceType = radioGroup.value;
        if (!this.validateAbsenceType(absenceType)) {
            radioGroup.setCustomValidity('Velg en type');
            radioGroup.reportValidity();
            radioGroup.focus();
            validInputs = false;
        } else {
            radioGroup.setCustomValidity('');
            radioGroup.reportValidity();
        }

        // Fetch input field values
        const absenceStartDateTime = this.refs.absenceStartDateTimeInput.value;
        const absenceEndDateTime = this.refs.absenceEndDateTimeInput.value;
        const absenceStartElement = this.refs.absenceStartDateTimeInput;
        if (absenceEndDateTime < absenceStartDateTime) {
            absenceStartElement.setCustomValidity('Starttid kan ikke komme etter sluttid');
            absenceStartElement.reportValidity();
            validInputs = false;
        } else {
            absenceStartElement.setCustomValidity('');
            absenceStartElement.reportValidity();
        }

        if (!validInputs) {
            return;
        }
        let result;
        try {
            result = await getConflictsForTimePeriod({
                startTimeInMilliseconds: new Date(absenceStartDateTime).getTime(),
                endTimeInMilliseconds: new Date(absenceEndDateTime).getTime()
            });
        } catch {
            const event = new ShowToastEvent({
                title: 'Det oppsto en feil',
                message: 'Feil ved henting av avtaler i dette tidsrommet, prøv igjen senere.',
                variant: 'error'
            });
            this.dispatchEvent(event);
            return;
        }

        const confirmation = await ConfimationModal.open({
            content: result,
            absenceType: absenceType,
            absenceStartDateTime: absenceStartDateTime,
            absenceEndDateTime: absenceEndDateTime
        });
        if (confirmation) {
            this.isLoading = true;
            try {
                await createAbsenceAndResolveConflicts({
                    absenceType: absenceType,
                    startTimeInMilliseconds: new Date(absenceStartDateTime).getTime(),
                    endTimeInMilliseconds: new Date(absenceEndDateTime).getTime()
                });
            } catch (error) {
                console.error(error);
                const event = new ShowToastEvent({
                    title: 'Kunne ikke legge til fravær',
                    message: 'Det oppstod en feil, prøv igjen senere',
                    variant: 'error'
                });
                this.dispatchEvent(event);
            }
            if (this.isEdit) {
                console.log('nå er vi edit');
                try {
                    await deleteAbsence({ recordId: this.event.extendedProps.recordId });
                    const event = new ShowToastEvent({
                        title: 'Fravær endret',
                        message: 'Fravær ble endret, og eventuelle konflikter ble løst',
                        variant: 'success'
                    });
                    this.dispatchEvent(event);
                } catch {
                    const event = new ShowToastEvent({
                        title: 'Det oppsto en feil',
                        message: 'Feil ved endring av avtale, prøv igjen senere.',
                        variant: 'error'
                    });
                    this.dispatchEvent(event);
                }
            } else {
                const event = new ShowToastEvent({
                    title: 'Fravær lagt til',
                    message: 'Fravær lagt til, og eventuelle konflikter ble løst',
                    variant: 'success'
                });
                this.dispatchEvent(event);
            }
            this.isLoading = false;
            this.close(true);
        }
    }
    async handleDeleteAbsence() {
        const deleteConfirm = await DeleteConfimationModal.open();
        if (deleteConfirm) {
            this.isLoading = true;
            try {
                await deleteAbsence({ recordId: this.event.extendedProps.recordId });
                const event = new ShowToastEvent({
                    title: 'Fravær slettet',
                    message: 'Fraværet ble slettet vellykket',
                    variant: 'success'
                });
                this.dispatchEvent(event);
            } catch {
                const event = new ShowToastEvent({
                    title: 'Noe gikk galt',
                    message: 'Kunne ikke slette, prøv igjen senere',
                    variant: 'error'
                });
                this.dispatchEvent(event);
            }
            this.isLoading = false;
            this.close(true);
        } else {
            this.close(false);
        }
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
