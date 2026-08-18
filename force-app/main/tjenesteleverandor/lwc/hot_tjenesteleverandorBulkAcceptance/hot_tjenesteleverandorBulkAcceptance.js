import { LightningElement, api } from 'lwc';
import acceptServiceAppointments from '@salesforce/apex/HOT_TjenesteleverandorAcceptanceService.acceptServiceAppointments';
import declineServiceAppointments from '@salesforce/apex/HOT_TjenesteleverandorAcceptanceService.declineServiceAppointments';

export default class HotTjenesteleverandorBulkAcceptance extends LightningElement {
    @api appointments = [];
    @api action = 'accept';

    isProcessing = false;
    errorMessage;

    get appointmentCount() {
        return this.appointments?.length || 0;
    }

    get appointmentCountLabel() {
        return `${this.appointmentCount} oppdrag er valgt.`;
    }

    get isDeclineAction() {
        return this.action === 'decline';
    }

    get heading() {
        return this.isDeclineAction ? 'Bekreft avslag på valgte oppdrag' : 'Bekreft valgte oppdrag';
    }

    get instructionText() {
        const actionText = this.isDeclineAction ? 'avslår' : 'aksepterer';
        return `Kontroller oppdragene før du ${actionText}. ${this.appointmentCountLabel}`;
    }

    get reviewTableAriaLabel() {
        const actionText = this.isDeclineAction ? 'avslås' : 'aksepteres';
        return `Valgte oppdrag som skal ${actionText}`;
    }

    get confirmButtonStyling() {
        return this.isDeclineAction ? 'danger' : 'primary';
    }

    get confirmButtonLabel() {
        if (this.isProcessing) {
            return this.isDeclineAction ? 'Avslår …' : 'Aksepterer …';
        }
        const actionText = this.isDeclineAction ? 'Avslå' : 'Aksepter';
        return `${actionText} ${this.appointmentCount} oppdrag`;
    }

    get confirmButtonAriaLabel() {
        const actionText = this.isDeclineAction ? 'Avslå' : 'Aksepter';
        return `${actionText} ${this.appointmentCount} valgte oppdrag`;
    }

    get isConfirmDisabled() {
        return this.isProcessing || this.appointmentCount === 0;
    }

    get processingText() {
        return this.isDeclineAction ? 'Avslår valgte oppdrag' : 'Aksepterer valgte oppdrag';
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
            const responseMethod = this.isDeclineAction ? declineServiceAppointments : acceptServiceAppointments;
            const results = await responseMethod({
                serviceAppointmentIds: this.appointments.map((appointment) => appointment.Id)
            });
            this.dispatchEvent(new CustomEvent('responsecomplete', { detail: { results, action: this.action } }));
        } catch (error) {
            this.errorMessage =
                error?.body?.message ||
                (this.isDeclineAction
                    ? 'Oppdragene kunne ikke avslås. Gå tilbake til listen og prøv igjen.'
                    : 'Oppdragene kunne ikke aksepteres. Gå tilbake til listen og prøv igjen.');
        } finally {
            this.isProcessing = false;
        }
    }
}
