import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';

const CANCELLATION_FIELDS = [
    'HOT_CancelComment__c',
    'HOT_CanceledByInterpreter__c',
    'HOT_CanceledDate__c',
    'HOT_LateCancellation__c'
];

export default class HotTjenesteleverandorServiceAppointmentDetail extends NavigationMixin(LightningElement) {
    @api recordId;

    routeRecordId;

    isLoading = true;
    hasError = false;
    hasCancellationDetails = false;

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

    handleLoad(event) {
        const record = event.detail?.records?.[this.effectiveRecordId];
        const fields = record?.fields || {};

        this.hasCancellationDetails = CANCELLATION_FIELDS.some((fieldName) => {
            const value = fields[fieldName]?.value;
            return value !== null && value !== undefined && value !== '' && value !== false;
        });
        this.hasError = false;
        this.isLoading = false;
    }

    handleError() {
        this.hasError = true;
        this.isLoading = false;
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
