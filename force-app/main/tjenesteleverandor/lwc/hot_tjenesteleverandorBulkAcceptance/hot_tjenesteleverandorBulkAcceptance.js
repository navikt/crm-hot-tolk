import { LightningElement, api } from 'lwc';
import acceptServiceAppointments from '@salesforce/apex/HOT_TjenesteleverandorAcceptanceService.acceptServiceAppointments';

export default class HotTjenesteleverandorBulkAcceptance extends LightningElement {
    @api appointments = [];

    isProcessing = false;
    errorMessage;

    get appointmentCount() {
        return this.appointments?.length || 0;
    }

    get appointmentCountLabel() {
        return `${this.appointmentCount} oppdrag er valgt.`;
    }

    get acceptButtonLabel() {
        return this.isProcessing ? 'Aksepterer …' : `Aksepter ${this.appointmentCount} oppdrag`;
    }

    get acceptButtonAriaLabel() {
        return `Aksepter ${this.appointmentCount} valgte oppdrag`;
    }

    get isAcceptDisabled() {
        return this.isProcessing || this.appointmentCount === 0;
    }

    handleCancel() {
        if (!this.isProcessing) {
            this.dispatchEvent(new CustomEvent('cancel'));
        }
    }

    async handleAccept() {
        if (this.isAcceptDisabled) {
            return;
        }

        this.isProcessing = true;
        this.errorMessage = null;
        try {
            const results = await acceptServiceAppointments({
                serviceAppointmentIds: this.appointments.map((appointment) => appointment.Id)
            });
            this.dispatchEvent(new CustomEvent('acceptcomplete', { detail: { results } }));
        } catch (error) {
            this.errorMessage =
                error?.body?.message || 'Oppdragene kunne ikke aksepteres. Gå tilbake til listen og prøv igjen.';
        } finally {
            this.isProcessing = false;
        }
    }
}
