import LightningModal from 'lightning/modal';
import { api, track } from 'lwc';
import createAbsenceAndResolveConflicts from '@salesforce/apex/HOT_FreelanceAbsenceController.createAbsenceAndResolveConflicts';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ConfimationModal extends LightningModal {
    @api content;
    @api absenceType;
    @api absenceStartDateTime;
    @api absenceEndDateTime;
    @track isMobileView = false;

    connectedCallback() {
        this.updateViewMode();
        window.addEventListener('resize', this.updateViewMode);
    }

    disconnectedCallback() {
        window.removeEventListener('resize', this.updateViewMode);
    }

    updateViewMode = () => {
        this.isMobileView = window.innerWidth <= 600;
    };

    get hasConflicts() {
        return this.items && this.items.length > 0;
    }

    get items() {
        if (!this.content) {
            return [];
        }
        return this.content.map((item) => {
            return {
                number: item.ServiceAppointmentNumber,
                startTime: this.formatDate(item.startTimeInMilliseconds),
                endTime: this.formatDate(item.endTimeInMilliseconds),
                recordType: item.recordType === 'SERVICE_APPOINTMENT' ? 'Oppdrag' : 'Ledig på lønn'
            };
        });
    }

    formatDate(timestamp) {
        if (!timestamp) return '';
        const date = new Date(timestamp);
        const options = {
            year: 'numeric',
            month: '2-digit',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit',
            timeZone: 'Europe/Oslo'
        };
        return new Intl.DateTimeFormat('no-NO', options).format(date);
    }

    get formattedAbsenceStartDateTime() {
        return this.formatDate(this.absenceStartDateTime);
    }

    get formattedAbsenceEndDateTime() {
        return this.formatDate(this.absenceEndDateTime);
    }

    get modalHeader() {
        return this.hasConflicts ? 'Konflikter funnet' : 'Bekreft fravær';
    }

    handleOkay() {
        if (!this.absenceStartDateTime || !this.absenceEndDateTime) {
            return;
        }
        createAbsenceAndResolveConflicts({
            absenceType: this.absenceType,
            startTimeInMilliseconds: new Date(this.absenceStartDateTime).getTime(),
            endTimeInMilliseconds: new Date(this.absenceEndDateTime).getTime()
        })
            .then(() => {
                this.close(true);
            })
            .catch(() => {
                const event = new ShowToastEvent({
                    title: 'Kunne ikke legge til fravær',
                    message: 'Det oppstod en feil, prøv igjen senere',
                    variant: 'error'
                });
                this.dispatchEvent(event);
                this.close(false);
            });
    }

    handleDeny() {
        this.close(false);
    }
}
