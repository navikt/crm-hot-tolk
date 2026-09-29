import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import canAcceptAppointments from '@salesforce/customPermission/HOT_AcceptTjenesteleverandorOppdrag';
import canDeclineAppointments from '@salesforce/customPermission/HOT_DeclineTjenesteleverandorOppdrag';
import acceptServiceAppointments from '@salesforce/apex/HOT_TjenesteleverandorAcceptanceService.acceptServiceAppointments';
import declineServiceAppointments from '@salesforce/apex/HOT_TjenesteleverandorAcceptanceService.declineServiceAppointments';

import APPOINTMENT_NUMBER_FIELD from '@salesforce/schema/ServiceAppointment.AppointmentNumber';
import HOT_FREELANCE_SUBJECT_FIELD from '@salesforce/schema/ServiceAppointment.HOT_FreelanceSubject__c';
import HOT_INFORMATION_FIELD from '@salesforce/schema/ServiceAppointment.HOT_Information__c';
import HOT_WORK_TYPE_NAME_FIELD from '@salesforce/schema/ServiceAppointment.HOT_WorkTypeName__c';
import HOT_ASSIGNMENT_TYPE_FIELD from '@salesforce/schema/ServiceAppointment.HOT_AssignmentType__c';
import HOT_PREPARATION_TIME_FIELD from '@salesforce/schema/ServiceAppointment.HOT_PreparationTime__c';
import HOT_TOTAL_NUMBER_OF_INTERPRETERS_FIELD from '@salesforce/schema/ServiceAppointment.HOT_TotalNumberOfInterpreters__c';
import HOT_NUMBER_OF_INTERESTED_RESOURCES_FIELD from '@salesforce/schema/ServiceAppointment.HOT_NumberOfInterestedResources__c';
import STATUS_FIELD from '@salesforce/schema/ServiceAppointment.Status';
import HOT_TJENESTELEVERANDOR_STATUS_FIELD from '@salesforce/schema/ServiceAppointment.HOT_TjenesteleverandorStatus__c';
import HOT_SERVICE_TERRITORY_NAME_FIELD from '@salesforce/schema/ServiceAppointment.HOT_ServiceTerritoryName__c';
import HOT_IS_ACUTE_FIELD from '@salesforce/schema/ServiceAppointment.HOT_IsAcute__c';
import HOT_IS_SCREEN_INTERPRETER_NEW_FIELD from '@salesforce/schema/ServiceAppointment.HOT_IsScreenInterpreterNew__c';
import HOT_IS_SERIEOPPDRAG_FIELD from '@salesforce/schema/ServiceAppointment.HOT_IsSerieoppdrag__c';
import HOT_IS_OTHER_ECONOMIC_PROVICER_FIELD from '@salesforce/schema/ServiceAppointment.HOT_IsOtherEconomicProvicer__c';
import HOT_IS_IMAGE_INTERPRETER_FIELD from '@salesforce/schema/ServiceAppointment.HOT_IsImageInterpreter__c';
import HOT_DAY_OF_WEEK_FIELD from '@salesforce/schema/ServiceAppointment.HOT_DayOfWeek__c';
import HOT_ADDRESS_FORMATED_FIELD from '@salesforce/schema/ServiceAppointment.HOT_AddressFormated__c';
import HOT_IS_RELEASED_TO_FREELANCE_FIELD from '@salesforce/schema/ServiceAppointment.HOT_IsReleasedToFreelance__c';
import HOT_TJENESTELEVERANDOR_DEADLINE_FIELD from '@salesforce/schema/ServiceAppointment.HOT_TjenesteleverandorDeadline__c';
import EARLIEST_START_TIME_FIELD from '@salesforce/schema/ServiceAppointment.EarliestStartTime';
import DUE_DATE_FIELD from '@salesforce/schema/ServiceAppointment.DueDate';
import HOT_CANCEL_COMMENT_FIELD from '@salesforce/schema/ServiceAppointment.HOT_CancelComment__c';
import HOT_CANCELED_BY_INTERPRETER_FIELD from '@salesforce/schema/ServiceAppointment.HOT_CanceledByInterpreter__c';
import HOT_CANCELED_DATE_FIELD from '@salesforce/schema/ServiceAppointment.HOT_CanceledDate__c';
import HOT_LATE_CANCELLATION_FIELD from '@salesforce/schema/ServiceAppointment.HOT_LateCancellation__c';

const CANCELLATION_FIELDS = [
    HOT_CANCEL_COMMENT_FIELD,
    HOT_CANCELED_BY_INTERPRETER_FIELD,
    HOT_CANCELED_DATE_FIELD,
    HOT_LATE_CANCELLATION_FIELD
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

const FIELDS = [
    APPOINTMENT_NUMBER_FIELD,
    HOT_FREELANCE_SUBJECT_FIELD,
    HOT_INFORMATION_FIELD,
    HOT_WORK_TYPE_NAME_FIELD,
    HOT_ASSIGNMENT_TYPE_FIELD,
    HOT_PREPARATION_TIME_FIELD,
    HOT_TOTAL_NUMBER_OF_INTERPRETERS_FIELD,
    HOT_NUMBER_OF_INTERESTED_RESOURCES_FIELD,
    STATUS_FIELD,
    HOT_TJENESTELEVERANDOR_STATUS_FIELD,
    HOT_SERVICE_TERRITORY_NAME_FIELD,
    HOT_IS_ACUTE_FIELD,
    HOT_IS_SCREEN_INTERPRETER_NEW_FIELD,
    HOT_IS_SERIEOPPDRAG_FIELD,
    HOT_IS_OTHER_ECONOMIC_PROVICER_FIELD,
    HOT_IS_IMAGE_INTERPRETER_FIELD,
    HOT_DAY_OF_WEEK_FIELD,
    HOT_ADDRESS_FORMATED_FIELD,
    HOT_IS_RELEASED_TO_FREELANCE_FIELD,
    HOT_TJENESTELEVERANDOR_DEADLINE_FIELD,
    EARLIEST_START_TIME_FIELD,
    DUE_DATE_FIELD,
    HOT_CANCEL_COMMENT_FIELD,
    HOT_CANCELED_BY_INTERPRETER_FIELD,
    HOT_CANCELED_DATE_FIELD,
    HOT_LATE_CANCELLATION_FIELD
];
export default class HotTjenesteleverandorServiceAppointmentDetail extends NavigationMixin(LightningElement) {
    @api recordId;

    routeRecordId;
    recordData;

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

    @wire(getRecord, { recordId: '$effectiveRecordId', fields: FIELDS })
    wiredRecord({ data, error }) {
        if (data) {
            this.recordData = data;
            this.hasError = false;
            this.isLoading = false;
            this.syncRecordState();
            return;
        }
        if (error) {
            this.recordData = undefined;
            this.handleError();
        }
    }

    get effectiveRecordId() {
        return this.recordId || this.routeRecordId;
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

    get hasRecordData() {
        return Boolean(this.recordData);
    }

    get appointmentTags() {
        const tags = [];
        if (this.getFieldValue(HOT_IS_ACUTE_FIELD) === true) {
            tags.push({ id: 'acute', label: 'Akuttvaktoppdrag' });
        }
        if (this.getFieldValue(HOT_IS_IMAGE_INTERPRETER_FIELD) === true) {
            tags.push({ id: 'image', label: 'Bildetolk' });
        }
        if (this.getFieldValue(HOT_IS_SCREEN_INTERPRETER_NEW_FIELD) === true) {
            tags.push({ id: 'screen', label: 'Skjermtolk' });
        }
        if (this.getFieldValue(HOT_IS_SERIEOPPDRAG_FIELD) === true) {
            tags.push({ id: 'series', label: 'Serieoppdrag' });
        }
        return tags;
    }

    get hasAppointmentTags() {
        return this.appointmentTags.length > 0;
    }

    get appointmentNumber() {
        return this.displayValue(this.getFieldValue(APPOINTMENT_NUMBER_FIELD));
    }

    get freelanceSubject() {
        return this.displayValue(this.getFieldValue(HOT_FREELANCE_SUBJECT_FIELD));
    }

    get information() {
        return this.displayValue(this.getFieldValue(HOT_INFORMATION_FIELD));
    }

    get workTypeName() {
        return this.displayValue(this.getFieldValue(HOT_WORK_TYPE_NAME_FIELD));
    }

    get assignmentType() {
        return this.displayValue(this.getFieldValue(HOT_ASSIGNMENT_TYPE_FIELD));
    }

    get preparationTime() {
        return this.displayValue(this.getFieldValue(HOT_PREPARATION_TIME_FIELD));
    }

    get totalInterpreters() {
        return this.displayValue(this.getFieldValue(HOT_TOTAL_NUMBER_OF_INTERPRETERS_FIELD));
    }

    get interestedResources() {
        return this.displayValue(this.getFieldValue(HOT_NUMBER_OF_INTERESTED_RESOURCES_FIELD));
    }

    get status() {
        return this.displayValue(this.getFieldValue(STATUS_FIELD));
    }

    get providerStatus() {
        return this.displayValue(this.getFieldValue(HOT_TJENESTELEVERANDOR_STATUS_FIELD));
    }

    get serviceTerritory() {
        return this.displayValue(this.getFieldValue(HOT_SERVICE_TERRITORY_NAME_FIELD));
    }

    get isOtherEconomicProvider() {
        return this.getFieldValue(HOT_IS_OTHER_ECONOMIC_PROVICER_FIELD) === true ? 'Ja' : 'Nei';
    }

    get earliestStartTime() {
        return this.getFieldValue(EARLIEST_START_TIME_FIELD);
    }

    get dueDate() {
        return this.getFieldValue(DUE_DATE_FIELD);
    }

    get dayOfWeek() {
        return this.displayValue(this.getFieldValue(HOT_DAY_OF_WEEK_FIELD));
    }

    get durationText() {
        if (!this.earliestStartTime || !this.dueDate) {
            return '—';
        }
        const durationInHours =
            (new Date(this.dueDate).getTime() - new Date(this.earliestStartTime).getTime()) / 3600000;
        if (!Number.isFinite(durationInHours) || durationInHours <= 0) {
            return '—';
        }
        const roundedDuration = Number.isInteger(durationInHours) ? durationInHours : durationInHours.toFixed(1);
        return `${roundedDuration} timer`;
    }

    get addressFormatted() {
        return this.displayValue(this.getFieldValue(HOT_ADDRESS_FORMATED_FIELD));
    }

    get cancellationComment() {
        return this.displayValue(this.getFieldValue(HOT_CANCEL_COMMENT_FIELD));
    }

    get canceledByInterpreter() {
        return this.getFieldValue(HOT_CANCELED_BY_INTERPRETER_FIELD) === true ? 'Ja' : 'Nei';
    }

    get canceledDate() {
        return this.getFieldValue(HOT_CANCELED_DATE_FIELD);
    }

    get lateCancellation() {
        return this.getFieldValue(HOT_LATE_CANCELLATION_FIELD) === true ? 'Ja' : 'Nei';
    }

    get assignedResourceDescription() {
        const interestedResources = this.getFieldValue(HOT_NUMBER_OF_INTERESTED_RESOURCES_FIELD);
        if (interestedResources > 0) {
            return `${interestedResources} interessert${interestedResources === 1 ? '' : 'e'} tolk${interestedResources === 1 ? '' : 'er'}`;
        }
        return 'Ingen tildelte ressurser ennå';
    }

    syncRecordState() {
        console.log('ServiceAppointment wire data loaded:', {
            recordId: this.effectiveRecordId,
            fields: this.recordData?.fields
        });

        this.hasCancellationDetails = CANCELLATION_FIELDS.some((fieldName) => {
            const value = this.getFieldValue(fieldName);
            return value !== null && value !== undefined && value !== '' && value !== false;
        });
        this.acceptanceDeadline = this.getFieldValue(HOT_TJENESTELEVERANDOR_DEADLINE_FIELD);
        const acceptanceDeadlineTime = this.acceptanceDeadline ? new Date(this.acceptanceDeadline).getTime() : NaN;
        this.isAcceptanceEligible =
            this.getFieldValue(HOT_TJENESTELEVERANDOR_STATUS_FIELD) === 'Transferred' &&
            this.getFieldValue(STATUS_FIELD) === 'Released to Freelance' &&
            this.getFieldValue(HOT_IS_RELEASED_TO_FREELANCE_FIELD) === true &&
            Number.isFinite(acceptanceDeadlineTime) &&
            acceptanceDeadlineTime > Date.now();
    }

    handleError() {
        this.hasError = true;
        this.isAcceptanceEligible = false;
        this.isLoading = false;
    }

    getFieldValue(fieldName) {
        return this.recordData ? getFieldValue(this.recordData, fieldName) : undefined;
    }

    displayValue(value) {
        return value === null || value === undefined || value === '' ? '—' : value;
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
