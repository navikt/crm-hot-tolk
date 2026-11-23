import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue, getFieldDisplayValue } from 'lightning/uiRecordApi';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
import { refreshApex } from '@salesforce/apex';
import { RefreshEvent } from 'lightning/refresh';
import icons from '@salesforce/resourceUrl/ikoner';
import canAcceptAppointments from '@salesforce/customPermission/HOT_AcceptTjenesteleverandorOppdrag';
import acceptServiceAppointments from '@salesforce/apex/HOT_TjenesteleverandorAcceptanceService.acceptServiceAppointments';

import APPOINTMENT_NUMBER_FIELD from '@salesforce/schema/ServiceAppointment.AppointmentNumber';
import HOT_FREELANCE_SUBJECT_FIELD from '@salesforce/schema/ServiceAppointment.HOT_FreelanceSubject__c';
import HOT_INFORMATION_FIELD from '@salesforce/schema/ServiceAppointment.HOT_Information__c';
import HOT_WORK_TYPE_NAME_FIELD from '@salesforce/schema/ServiceAppointment.HOT_WorkTypeName__c';
import HOT_ASSIGNMENT_TYPE_FIELD from '@salesforce/schema/ServiceAppointment.HOT_AssignmentType__c';
import HOT_USER_PREFERRED_GENDER_FIELD from '@salesforce/schema/ServiceAppointment.HOT_UserPreferredGender__c';
import HOT_USER_PREFERRED_INTERPRETER_FIELD from '@salesforce/schema/ServiceAppointment.HOT_UserPreferredInterpreter__c';
import HOT_USER_INTERPRETATION_METHOD_FIELD from '@salesforce/schema/ServiceAppointment.HOT_UserInterpretationMethod__c';
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
import HOT_TL_DISPATCHER_NAME_FIELD from '@salesforce/schema/ServiceAppointment.HOT_TLDispatcher__r.Name';
import HOT_PERSON_RESERVATIONS_FIELD from '@salesforce/schema/ServiceAppointment.HOT_Request__r.Person__r.HOT_Reservations__c';
import HOT_PERSON_LANGUAGE_AND_COMMUNICATION_METHODS_FIELD from '@salesforce/schema/ServiceAppointment.HOT_Request__r.Person__r.HOT_LanguageAndCommunicationMethods__c';
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
const RESERVED_LIST_REFRESH_KEY = 'tjenesteleverandorReservedListRefresh';
const PERSON_INFORMATION_FIELDS = [HOT_PERSON_RESERVATIONS_FIELD, HOT_PERSON_LANGUAGE_AND_COMMUNICATION_METHODS_FIELD];

const TAG_DEFINITIONS = [
    { id: 'acute', field: HOT_IS_ACUTE_FIELD, label: 'Akuttvaktoppdrag', color: 'danger' },
    { id: 'image', field: HOT_IS_IMAGE_INTERPRETER_FIELD, label: 'Bildetolk', color: 'info' },
    { id: 'screen', field: HOT_IS_SCREEN_INTERPRETER_NEW_FIELD, label: 'Skjermtolk', color: 'success' },
    { id: 'series', field: HOT_IS_SERIEOPPDRAG_FIELD, label: 'Serieoppdrag', color: 'warning' }
];

const FIELDS = [
    APPOINTMENT_NUMBER_FIELD,
    HOT_FREELANCE_SUBJECT_FIELD,
    HOT_INFORMATION_FIELD,
    HOT_WORK_TYPE_NAME_FIELD,
    HOT_ASSIGNMENT_TYPE_FIELD,
    HOT_USER_PREFERRED_GENDER_FIELD,
    HOT_USER_PREFERRED_INTERPRETER_FIELD,
    HOT_USER_INTERPRETATION_METHOD_FIELD,
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
    HOT_TL_DISPATCHER_NAME_FIELD,
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
    isAssignmentOpen = false;
    assignmentError;
    pageScrollLock;
    exitCrossIcon = icons + '/Close/Close.svg';
    isAcceptanceEligible = false;
    acceptanceDeadline;
    responseFeedback;

    renderedCallback() {
        if (!this.isAssignmentOpen) {
            return;
        }
        if (!this.pageScrollLock) {
            const element = document.scrollingElement;
            this.pageScrollLock = {
                element,
                overflow: element.style.getPropertyValue('overflow'),
                priority: element.style.getPropertyPriority('overflow')
            };
            element.style.setProperty('overflow', 'hidden', 'important');
        }
        const dialog = this.template.querySelector('[data-id="assignment-dialog"]');
        if (dialog && !dialog.open) {
            dialog.showModal();
        }
    }

    disconnectedCallback() {
        this.unlockPageScroll();
    }

    unlockPageScroll() {
        if (this.pageScrollLock) {
            const { element, overflow, priority } = this.pageScrollLock;
            if (overflow) {
                element.style.setProperty('overflow', overflow, priority);
            } else {
                element.style.removeProperty('overflow');
            }
            this.pageScrollLock = undefined;
        }
    }

    get assignmentInputVariables() {
        return [{ name: 'recordId', type: 'String', value: this.effectiveRecordId }];
    }

    @wire(CurrentPageReference)
    handlePageReference(pageReference) {
        this.routeRecordId = pageReference?.state?.c__recordId;
    }

    @wire(getRecord, { recordId: '$effectiveRecordId', fields: FIELDS, optionalFields: PERSON_INFORMATION_FIELDS })
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
        return this.routeRecordId || this.recordId;
    }

    assignedResourceResult;
    assignedResourceUrl;
    assignedResourceUrlError;

    @wire(getRelatedListRecords, {
        parentRecordId: '$effectiveRecordId',
        relatedListId: 'ServiceResources',
        fields: ['AssignedResource.Id', 'AssignedResource.ServiceResourceId', 'AssignedResource.ServiceResource.Name'],
        pageSize: 1
    })
    async wiredAssignedResource(result) {
        this.assignedResourceResult = result;
        this.assignedResourceUrl = undefined;
        this.assignedResourceUrlError = undefined;
        const record = result.data?.records[0];
        const recordId = getFieldValue(record, 'AssignedResource.ServiceResourceId');
        if (!recordId) {
            return;
        }
        try {
            const url = await this[NavigationMixin.GenerateUrl]({
                type: 'comm__namedPage',
                attributes: { name: 'Tjenesteressursdetaljer__c' },
                state: {
                    c__recordId: recordId,
                    c__serviceAppointmentId: this.effectiveRecordId
                }
            });
            if (this.assignedResourceResult === result) {
                this.assignedResourceUrl = url;
            }
        } catch (error) {
            if (this.assignedResourceResult === result) {
                console.error('Error generating service resource URL:', error);
                this.assignedResourceUrlError = error;
            }
        }
    }

    get assignedResourceName() {
        const record = this.assignedResourceResult?.data?.records[0];
        return this.displayValue(getFieldValue(record, 'AssignedResource.ServiceResource.Name'));
    }

    get assignedResourceError() {
        return this.assignedResourceResult?.error || this.assignedResourceUrlError;
    }

    get showAcceptAction() {
        return Boolean(canAcceptAppointments && this.isAcceptanceEligible);
    }

    get showAssignOrReserveAction() {
        const status = this.getFieldValue(STATUS_FIELD);
        return (
            this.getFieldValue(HOT_TJENESTELEVERANDOR_STATUS_FIELD) === 'Accepted' &&
            Boolean(status) &&
            !['Completed', 'Canceled', 'Annul', 'In Progress', 'Cannot Complete'].includes(status)
        );
    }

    get hasRecordData() {
        return Boolean(this.recordData);
    }

    get appointmentTags() {
        return TAG_DEFINITIONS.filter(({ field }) => this.getFieldValue(field) === true);
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

    get userPreferredGender() {
        return this.displayValue(this.getFieldValue(HOT_USER_PREFERRED_GENDER_FIELD));
    }
    get userPreferredInterpreter() {
        return this.displayValue(this.getFieldValue(HOT_USER_PREFERRED_INTERPRETER_FIELD));
    }

    get userInterpretationMethod() {
        const label = this.recordData
            ? getFieldDisplayValue(this.recordData, HOT_USER_INTERPRETATION_METHOD_FIELD)
            : undefined;
        return this.displayValue(label ?? this.getFieldValue(HOT_USER_INTERPRETATION_METHOD_FIELD));
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
        return this.displayValue(this.getFieldLabel(STATUS_FIELD));
    }

    get showStatusTag() {
        return ['Scheduled', 'Dispatched'].includes(this.getFieldValue(STATUS_FIELD));
    }

    get statusTagColor() {
        const status = this.getFieldValue(STATUS_FIELD);
        if (status === 'Scheduled') {
            return 'warning';
        }
        return status === 'Dispatched' ? 'info' : 'neutral';
    }

    get statusTagVariant() {
        return this.getFieldValue(STATUS_FIELD) === 'Dispatched' ? 'outline' : 'moderate';
    }

    get providerStatus() {
        return this.displayValue(this.getFieldValue(HOT_TJENESTELEVERANDOR_STATUS_FIELD));
    }

    get providerStatusLabel() {
        return this.displayValue(this.getFieldLabel(HOT_TJENESTELEVERANDOR_STATUS_FIELD));
    }

    get showProviderResourceSections() {
        return this.providerStatus === 'Accepted';
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

    get providerDispatcherName() {
        return this.displayValue(this.getFieldValue(HOT_TL_DISPATCHER_NAME_FIELD));
    }

    get personReservations() {
        return this.displayValue(this.getFieldValue(HOT_PERSON_RESERVATIONS_FIELD));
    }

    get personLanguageAndCommunicationMethods() {
        return this.displayValue(this.getFieldValue(HOT_PERSON_LANGUAGE_AND_COMMUNICATION_METHODS_FIELD));
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

    getFieldLabel(fieldName) {
        if (!this.recordData) {
            return undefined;
        }
        return getFieldDisplayValue(this.recordData, fieldName) ?? getFieldValue(this.recordData, fieldName);
    }

    displayValue(value) {
        return value === null || value === undefined || value === '' ? '—' : value;
    }

    async handleAccept() {
        if (!this.showAcceptAction || this.isResponding) {
            return;
        }

        this.isResponding = true;
        this.responseFeedback = undefined;
        const fallbackErrorMessage = 'Oppdraget kunne ikke bekreftes. Last inn siden og prøv igjen.';

        try {
            const results = await acceptServiceAppointments({
                serviceAppointmentIds: [this.effectiveRecordId]
            });
            const result = results?.[0];
            if (!result?.success) {
                this.responseFeedback = { type: 'error', message: result?.message || fallbackErrorMessage };
                return;
            }

            this.isAcceptanceEligible = false;
            this.responseFeedback = { type: 'success', message: result.message || 'Oppdraget er bekreftet.' };
            this.markListsForRefresh();
            await notifyRecordUpdateAvailable([{ recordId: this.effectiveRecordId }]);
        } catch (error) {
            this.responseFeedback = { type: 'error', message: error?.body?.message || fallbackErrorMessage };
        } finally {
            this.isResponding = false;
        }
    }

    handleAssignOrReserve() {
        this.isAssignmentOpen = true;
        this.assignmentError = undefined;
        this.responseFeedback = undefined;
    }

    closeAssignmentModal() {
        this.isAssignmentOpen = false;
        const dialog = this.template.querySelector('[data-id="assignment-dialog"]');
        if (dialog?.open) {
            dialog.close();
        }
        this.unlockPageScroll();
    }

    async handleAssignmentStatusChange(event) {
        const { status } = event.detail;
        if (status === 'ERROR') {
            this.assignmentError = 'Tildelingen kunne ikke fullføres. Lukk vinduet og prøv igjen.';
            return;
        }
        if (status !== 'FINISHED' && status !== 'FINISHED_SCREEN') {
            return;
        }
        this.closeAssignmentModal();
        try {
            this.markListsForRefresh();
            await notifyRecordUpdateAvailable([{ recordId: this.effectiveRecordId }]);
            await refreshApex(this.assignedResourceResult);
            this.dispatchEvent(new RefreshEvent());
        } catch (error) {
            this.responseFeedback = {
                type: 'error',
                message: error?.body?.message || error?.message || 'Kunne ikke åpne eller oppdatere tildelingen.'
            };
        }
    }

    markListsForRefresh() {
        const marker = JSON.stringify({ recordId: this.effectiveRecordId, timestamp: Date.now() });
        sessionStorage.setItem(TRANSFERRED_LIST_REFRESH_KEY, marker);
        sessionStorage.setItem(ACCEPTED_LIST_REFRESH_KEY, marker);
        sessionStorage.setItem(RESERVED_LIST_REFRESH_KEY, marker);
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
