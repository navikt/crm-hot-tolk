import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import canAcceptAppointments from '@salesforce/customPermission/HOT_AcceptTjenesteleverandorOppdrag';
import acceptServiceAppointments from '@salesforce/apex/HOT_TjenesteleverandorAcceptanceService.acceptServiceAppointments';

const CANCELLATION_FIELDS = [
    'HOT_CancelComment__c',
    'HOT_CanceledByInterpreter__c',
    'HOT_CanceledDate__c',
    'HOT_LateCancellation__c'
];

function createFeedback(type, message) {
    const success = type === 'success';
    return {
        message,
        className: success
            ? 'slds-notify slds-notify_alert slds-theme_success acceptance-message'
            : 'slds-notify slds-notify_alert slds-alert_error acceptance-message',
        role: success ? 'status' : 'alert',
        icon: success ? 'utility:success' : 'utility:error'
    };
}

export default class HotTjenesteleverandorServiceAppointmentDetail extends NavigationMixin(LightningElement) {
    @api recordId;

    routeRecordId;

    isLoading = true;
    hasError = false;
    hasCancellationDetails = false;
    isAccepting = false;
    isAcceptanceEligible = false;
    acceptanceDeadline;
    acceptanceFeedback;

    @wire(CurrentPageReference)
    handlePageReference(pageReference) {
        this.routeRecordId = pageReference?.state?.c__recordId;
    }

    get effectiveRecordId() {
        return this.recordId || this.routeRecordId;
    }

    get recordFormClass() {
        return this.isLoading || this.hasError ? 'record-form record-form_hidden' : 'record-form';
    }

    get cancellationSectionClass() {
        return this.hasCancellationDetails ? 'detail-section' : 'detail-section detail-section_hidden';
    }

    get showAcceptanceAction() {
        return Boolean(canAcceptAppointments && this.isAcceptanceEligible);
    }

    handleLoad(event) {
        const record = event.detail?.records?.[this.effectiveRecordId];
        const fields = record?.fields || {};

        this.hasCancellationDetails = CANCELLATION_FIELDS.some((fieldName) => {
            const value = fields[fieldName]?.value;
            return value !== null && value !== undefined && value !== '' && value !== false;
        });
        this.acceptanceDeadline = fields.HOT_TjenesteleverandorDeadline__c?.value;
        this.isAcceptanceEligible =
            fields.HOT_TjenesteleverandorStatus__c?.value === 'Transferred' &&
            fields.Status?.value === 'Released to Freelance' &&
            fields.HOT_IsReleasedToFreelance__c?.value === true &&
            Boolean(this.acceptanceDeadline) &&
            new Date(this.acceptanceDeadline).getTime() > Date.now();
        this.hasError = false;
        this.isLoading = false;
    }

    handleError() {
        this.hasError = true;
        this.isAcceptanceEligible = false;
        this.isLoading = false;
    }

    async handleAccept() {
        if (!this.showAcceptanceAction || this.isAccepting) {
            return;
        }

        this.isAccepting = true;
        this.acceptanceFeedback = undefined;

        try {
            const results = await acceptServiceAppointments({
                serviceAppointmentIds: [this.effectiveRecordId]
            });
            const result = results?.[0];
            if (!result?.success) {
                this.acceptanceFeedback = createFeedback(
                    'error',
                    result?.message || 'Oppdraget kunne ikke aksepteres. Last inn siden og prøv igjen.'
                );
                return;
            }

            this.isAcceptanceEligible = false;
            this.acceptanceFeedback = createFeedback('success', result.message || 'Oppdraget er akseptert.');
            await notifyRecordUpdateAvailable([{ recordId: this.effectiveRecordId }]);
        } catch (error) {
            this.acceptanceFeedback = createFeedback(
                'error',
                error?.body?.message || 'Oppdraget kunne ikke aksepteres. Last inn siden og prøv igjen.'
            );
        } finally {
            this.isAccepting = false;
        }
    }

    handleBack() {
        if (window.history && window.history.length > 1) {
            window.history.back();
            return;
        }

        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'home'
            }
        });
    }
}
