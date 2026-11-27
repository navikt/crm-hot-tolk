import { LightningElement, api } from 'lwc';
import acceptServiceAppointments from '@salesforce/apex/HOT_TjenesteleverandorAcceptanceService.acceptServiceAppointments';
import canAcceptAppointments from '@salesforce/customPermission/HOT_AcceptTjenesteleverandorOppdrag';

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

    get instructionText() {
        return `Kontroller oppdragene før du bekrefter. ${this.appointmentCountLabel}`;
    }

    get confirmButtonLabel() {
        if (this.isProcessing) {
            return 'Bekrefter …';
        }
        return `Bekreft ${this.appointmentCount} oppdrag`;
    }

    get confirmButtonAriaLabel() {
        return `Bekreft ${this.appointmentCount} valgte oppdrag`;
    }

    get isConfirmDisabled() {
        return !canAcceptAppointments || this.isProcessing || this.appointmentCount === 0;
    }

    handleCancel() {
        if (!this.isProcessing) {
            this.dispatchEvent(new CustomEvent('cancel'));
        }
    }

    async handleConfirm() {
        if (this.isConfirmDisabled) {
            return;
        }

        this.isProcessing = true;
        this.errorMessage = null;
        try {
            const results = await acceptServiceAppointments({
                serviceAppointmentIds: this.appointments.map((appointment) => appointment.Id)
            });
            this.dispatchEvent(new CustomEvent('responsecomplete', { detail: { results } }));
        } catch (error) {
            this.errorMessage =
                error?.body?.message || 'Oppdragene kunne ikke bekreftes. Gå tilbake til listen og prøv igjen.';
        } finally {
            this.isProcessing = false;
        }
    }
}
