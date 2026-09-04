import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import canAcceptAppointments from '@salesforce/customPermission/HOT_AcceptTjenesteleverandorOppdrag';
import canDeclineAppointments from '@salesforce/customPermission/HOT_DeclineTjenesteleverandorOppdrag';
import acceptServiceAppointments from '@salesforce/apex/HOT_TjenesteleverandorAcceptanceService.acceptServiceAppointments';
import declineServiceAppointments from '@salesforce/apex/HOT_TjenesteleverandorAcceptanceService.declineServiceAppointments';

const CANCELLATION_FIELDS = [
    'HOT_CancelComment__c',
    'HOT_CanceledByInterpreter__c',
    'HOT_CanceledDate__c',
    'HOT_LateCancellation__c'
];
const TRANSFERRED_LIST_REFRESH_KEY = 'tjenesteleverandorTransferredListRefresh';
const ACCEPTED_LIST_REFRESH_KEY = 'tjenesteleverandorAcceptedListRefresh';

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
    isResponding = false;
    isAcceptanceEligible = false;
    acceptanceDeadline;
    responseFeedback;

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

    get showResponseAction() {
        return this.showAcceptAction || this.showDeclineAction;
    }

    get showAcceptAction() {
        return Boolean(canAcceptAppointments && this.isAcceptanceEligible);
    }

    get showDeclineAction() {
        return Boolean(canDeclineAppointments && this.isAcceptanceEligible);
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
        if (!this.showAcceptAction) {
            return;
        }
        await this.respondToAppointment(
            'accept',
            acceptServiceAppointments,
            'Oppdraget kunne ikke aksepteres. Last inn siden og prøv igjen.',
            'Oppdraget er akseptert.'
        );
    }

    async handleDecline() {
        if (!this.showDeclineAction) {
            return;
        }
        await this.respondToAppointment(
            'decline',
            declineServiceAppointments,
            'Oppdraget kunne ikke avslås. Last inn siden og prøv igjen.',
            'Oppdraget er avslått.'
        );
    }

    async respondToAppointment(action, responseMethod, fallbackErrorMessage, fallbackSuccessMessage) {
        if (!this.showResponseAction || this.isResponding) {
            return;
        }

        this.isResponding = true;
        this.responseFeedback = undefined;

        try {
            const results = await responseMethod({
                serviceAppointmentIds: [this.effectiveRecordId]
            });
            const result = results?.[0];
            if (!result?.success) {
                this.responseFeedback = createFeedback('error', result?.message || fallbackErrorMessage);
                return;
            }

            this.isAcceptanceEligible = false;
            this.responseFeedback = createFeedback('success', result.message || fallbackSuccessMessage);
            this.markListsForRefresh(action);
            await notifyRecordUpdateAvailable([{ recordId: this.effectiveRecordId }]);
        } catch (error) {
            this.responseFeedback = createFeedback('error', error?.body?.message || fallbackErrorMessage);
        } finally {
            this.isResponding = false;
        }
    }

    markListsForRefresh(action) {
        const marker = JSON.stringify({ recordId: this.effectiveRecordId, timestamp: Date.now() });
        sessionStorage.setItem(TRANSFERRED_LIST_REFRESH_KEY, marker);
        if (action === 'accept') {
            sessionStorage.setItem(ACCEPTED_LIST_REFRESH_KEY, marker);
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
