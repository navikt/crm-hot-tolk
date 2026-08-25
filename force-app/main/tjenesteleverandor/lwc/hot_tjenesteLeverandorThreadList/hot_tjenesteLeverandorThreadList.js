import { LightningElement } from 'lwc';
import getAllThreads from '@salesforce/apex/HOT_TLThreadlistController.getAllTjenesteleverandorThreads';
import getServiceAppointmentDetails from '@salesforce/apex/HOT_TLThreadlistController.getServiceAppointmentDetails';
import getParticipants from '@salesforce/apex/HOT_ThreadParticipants.getParticipants';
import isCurrentUserTjenesteleverandor from '@salesforce/apex/HOT_MessageHelper.isCurrentUserTjenesteleverandor';
import { formatDatetimeinterval } from 'c/datetimeFormatterNorwegianTime';
import userId from '@salesforce/user/Id';
import icons from '@salesforce/resourceUrl/aksel_ikoner';

const VIEW_FILTERS = [
    {
        label: 'Alle samtaler',
        value: 'all',
        threadTypes: ['HOT_TJENESTELEVERANDOR-FORMIDLER', 'HOT_TJENESTELEVERANDOR-TOLK']
    },
    {
        label: 'Samtaler med Nav',
        value: 'nav',
        threadTypes: ['HOT_TJENESTELEVERANDOR-FORMIDLER']
    },
    {
        label: 'Samtaler med tolk',
        value: 'tolk',
        threadTypes: ['HOT_TJENESTELEVERANDOR-TOLK']
    }
];

export default class hot_tjenesteLeverandorThreadList extends LightningElement {
    faceCryIcon = icons + '/Interface/FaceCry.svg';

    activeFilter = 'all';
    showOnlyMine = false;
    searchTerm = '';
    selectedConversationId;
    conversations = [];
    isLoadingConversations = true;
    loadError;
    currentTimestamp = Date.now();
    relativeTimeRefreshInterval;
    serviceAppointment = null;
    relatedRecordId = null;
    showServiceAppointmentDetailsModal = false;
    isLoadingServiceAppointmentDetails = false;
    serviceAppointmentDetailsError;
    threadParticipants = [];
    readParticipants = [];
    isLoadingReadParticipants = false;
    isTjenesteleverandorFormidler = false;

    connectedCallback() {
        this.relativeTimeRefreshInterval = setInterval(() => {
            this.currentTimestamp = Date.now();
        }, MILLISECONDS_PER_MINUTE);
        this.loadConversations();
        this.checkTjenesteleverandorFormidler();
    }

    disconnectedCallback() {
        clearInterval(this.relativeTimeRefreshInterval);
    }

    handleThreadRead(event) {
        this.loadThreadParticipants(event.detail.threadId);
    }

    checkTjenesteleverandorFormidler() {
        isCurrentUserTjenesteleverandor()
            .then((result) => {
                this.isTjenesteleverandorFormidler = result;
            })
            .catch(() => {
                this.isTjenesteleverandorFormidler = false;
            });
    }

    get filterChips() {
        return this.configuredFilters.map((option) => ({
            label: option.label,
            value: option.value,
            type: 'toggle',
            selected: option.value === this.activeFilter
        }));
    }

    get configuredFilters() {
        return VIEW_FILTERS;
    }

    get filteredConversations() {
        const normalizedSearchTerm = this.searchTerm.trim().toLowerCase();
        const activeFilter =
            this.configuredFilters.find((filterOption) => filterOption.value === this.activeFilter) ??
            this.configuredFilters[0];

        return this.conversations
            .filter((conversation) => {
                const matchesFilter = activeFilter.threadTypes.includes(conversation.threadType);
                const matchesOwner = !this.showOnlyMine || conversation.ownerId === userId;
                const matchesSearch =
                    normalizedSearchTerm.length === 0 ||
                    conversation.subject.toLowerCase().includes(normalizedSearchTerm);

                return matchesFilter && matchesOwner && matchesSearch;
            })
            .sort(compareConversations);
    }

    get visibleConversations() {
        return this.filteredConversations.map((conversation) => {
            const isSelected = conversation.id === this.selectedConversationId;
            const statusLabel = conversation.isRead ? 'Lest' : 'Ulest';
            const latestMessage = formatLatestMessageDateTime(
                conversation.latestMessageDateTime,
                this.currentTimestamp
            );

            return {
                ...conversation,
                isSelected,
                ariaPressed: isSelected ? 'true' : 'false',
                statusLabel,
                latestMessage,
                rowClass: isSelected ? 'conversation-card conversation-card-selected' : 'conversation-card',
                statusColor: conversation.isRead ? 'success' : 'warning',
                ariaLabel: `${statusLabel}. ${conversation.subject}. Oppdrag ${conversation.appointmentTime}. ${conversation.participantLabel}. Siste melding sendt ${latestMessage}.`
            };
        });
    }

    get hasConversations() {
        return this.filteredConversations.length > 0;
    }

    get showEmptyState() {
        return !this.loadError && !this.hasConversations;
    }

    get selectedConversation() {
        const conversation = this.conversations.find(({ id }) => id === this.selectedConversationId);

        if (!conversation) {
            return null;
        }

        return {
            ...conversation,
            threadTypeLabel: `Samtale ${conversation.participantLabel.toLowerCase()}`
        };
    }

    get hasSelectedConversation() {
        return this.selectedConversation !== null;
    }

    get selectedConversationList() {
        return this.selectedConversation ? [this.selectedConversation] : [];
    }

    get hasReadParticipants() {
        return this.readParticipants.length > 0;
    }

    handleFilterToggle(event) {
        this.activeFilter = event.detail.chip.value;
        this.ensureSelectedConversationIsVisible();
    }

    handleMineSwitchChange(event) {
        this.showOnlyMine = event.detail.checked;
        this.ensureSelectedConversationIsVisible();
    }

    handleSearchChange(event) {
        this.searchTerm = event.target.value;
        this.ensureSelectedConversationIsVisible();
    }

    handleConversationSelect(event) {
        const conversationId = event.currentTarget.dataset.id;

        this.selectedConversationId = conversationId;

        const conversation = this.conversations.find(({ id }) => id === conversationId);

        this.relatedRecordId = conversation?.relatedRecordId || null;
        this.serviceAppointment = null;
        this.showServiceAppointmentDetailsModal = false;
        this.serviceAppointmentDetailsError = undefined;
        this.threadParticipants = [];
        this.readParticipants = [];
        this.loadThreadParticipants(conversationId);
        console.log('Selected conversation:', conversation);
        console.log('Related record ID:', this.relatedRecordId);
        console.log('Service appointment:', this.serviceAppointment);
    }

    async loadThreadParticipants(threadId) {
        this.isLoadingReadParticipants = true;

        try {
            const participants = await getParticipants({ threadId });
            if (this.selectedConversationId !== threadId) {
                return;
            }

            const threadType = this.selectedConversation?.threadType;
            this.threadParticipants = toThreadParticipantLabels(participants ?? [], threadType);
            this.readParticipants = toCounterpartyReadParticipants(participants ?? [], threadType);
        } catch (error) {
            if (this.selectedConversationId === threadId) {
                this.threadParticipants = [];
                this.readParticipants = [];
            }
        } finally {
            if (this.selectedConversationId === threadId) {
                this.isLoadingReadParticipants = false;
            }
        }
    }

    handleRefresh() {
        this.selectedConversationId = undefined;
        this.loadConversations();
    }

    async loadConversations() {
        this.isLoadingConversations = true;
        this.loadError = undefined;
        const startTime = Date.now();

        try {
            const threads = await getAllThreads();
            this.conversations = (threads ?? []).map(mapThreadToConversation);
            this.ensureSelectedConversationIsVisible();
        } catch (error) {
            this.conversations = [];
            this.loadError = 'Kunne ikke hente samtaler. Feilkode: ' + error;
        } finally {
            const remainingLoadingTime = MINIMUM_LOADING_DURATION_MS - (Date.now() - startTime);
            if (remainingLoadingTime > 0) {
                await wait(remainingLoadingTime);
            }
            this.currentTimestamp = Date.now();
            this.isLoadingConversations = false;
        }
    }

    ensureSelectedConversationIsVisible() {
        if (!this.filteredConversations.some((conversation) => conversation.id === this.selectedConversationId)) {
            this.selectedConversationId = undefined;
        }
    }

    async showServiceAppointmentDetails() {
        if (this.showServiceAppointmentDetailsModal) {
            this.showServiceAppointmentDetailsModal = false;
            return;
        }

        if (!this.relatedRecordId) {
            this.serviceAppointmentDetailsError = 'Fant ikke oppdraget som hører til denne samtalen.';
            return;
        }

        this.isLoadingServiceAppointmentDetails = true;
        this.serviceAppointmentDetailsError = undefined;
        try {
            this.serviceAppointment = await getServiceAppointmentDetails({ recordId: this.relatedRecordId });
            if (!this.serviceAppointment) {
                this.serviceAppointmentDetailsError = 'Fant ingen oppdragsdetaljer for denne samtalen.';
                return;
            }
            this.showServiceAppointmentDetailsModal = true;
        } catch (error) {
            this.serviceAppointmentDetailsError =
                error?.body?.message || 'Kunne ikke hente oppdragsdetaljer. Prøv igjen.';
        } finally {
            this.isLoadingServiceAppointmentDetails = false;
        }
    }

    get serviceAppointmentDetailsButtonLabel() {
        return this.showServiceAppointmentDetailsModal ? 'Skjul oppdragsdetaljer' : 'Vis oppdragsdetaljer';
    }

    get serviceAppointmentDetails() {
        return [
            { label: 'Oppdragsnummer', value: this.serviceAppointmentNumber },
            { label: 'Tema', value: this.serviceAppointmentSubject },
            { label: 'Tid', value: this.serviceAppointmentStartTimeEndTime },
            { label: 'Navn til bruker', value: this.serviceAppointmentUsernameSexAge },
            { label: 'Telefonnummer til bruker', value: this.serviceAppointmentUserPhoneNumber },
            { label: 'Tolkemetode', value: this.serviceAppointmentWorkTypeName },
            { label: 'Oppdragstype', value: this.serviceAppointmentType },
            { label: 'Status', value: this.serviceAppointmentStatus },
            { label: 'Medtolk', value: this.serviceAppointmentCoInterpreters }
        ].filter((detail) => detail.value);
    }
    get serviceAppointmentNumber() {
        return this.serviceAppointment?.AppointmentNumber || '';
    }
    get serviceAppointmentSubject() {
        return this.serviceAppointment?.Subject || '';
    }
    get serviceAppointmentStartTimeEndTime() {
        const startTime = this.serviceAppointment?.SchedStartTime || '';
        const endTime = this.serviceAppointment?.SchedEndTime || '';
        if (!startTime || !endTime) {
            return '';
        }
        return `${this.getDayOfWeek(startTime)} ${formatDatetimeinterval(startTime, endTime)}`;
    }
    get serviceAppointmentUsernameSexAge() {
        const confidentiality = this.serviceAppointment?.HOT_Request__r?.Account__r?.CRM_Person__r?.INT_Confidential__c;

        const userName =
            confidentiality === 'FORTROLIG' ? '' : this.serviceAppointment?.HOT_Request__r?.Account__r?.Name || '';
        const userSex = this.serviceAppointment?.HOT_Request__r?.Account__r?.CRM_Person__r?.INT_Sex__c || '';
        const userAge = this.serviceAppointment?.HOT_Request__r?.Account__r?.CRM_Person__r?.CRM_AgeNumber__c || '';
        return userName && userSex && userAge
            ? `${userName} (${userSex}, ${userAge} år)`
            : userName || userSex || userAge || '';
    }
    get serviceAppointmentUserPhoneNumber() {
        return this.serviceAppointment?.HOT_Request__r?.Account__r?.CRM_Person__r?.HOT_MobilePhone__c || '';
    }
    get serviceAppointmentType() {
        return this.serviceAppointment?.HOT_AssignmentType__c || '';
    }
    get serviceAppointmentStatus() {
        return this.serviceAppointment?.Status || '';
    }
    get serviceAppointmentCoInterpreters() {
        return this.serviceAppointment?.HOT_Interpreters__c || '';
    }
    get serviceAppointmentWorkTypeName() {
        return this.serviceAppointment?.HOT_WorkTypeName__c || '';
    }
    getDayOfWeek(date) {
        const jsDate = new Date(date);
        const dayOfWeek = jsDate.getDay();
        let dayOfWeekString;
        switch (dayOfWeek) {
            case 0:
                dayOfWeekString = 'Søndag';
                break;
            case 1:
                dayOfWeekString = 'Mandag';
                break;
            case 2:
                dayOfWeekString = 'Tirsdag';
                break;
            case 3:
                dayOfWeekString = 'Onsdag';
                break;
            case 4:
                dayOfWeekString = 'Torsdag';
                break;
            case 5:
                dayOfWeekString = 'Fredag';
                break;
            case 6:
                dayOfWeekString = 'Lørdag';
                break;
            default:
                dayOfWeekString = '';
        }
        return dayOfWeekString;
    }
}

const NORWEGIAN_DATE_TIME_FORMATTER = new Intl.DateTimeFormat('nb-NO', {
    day: 'numeric',
    month: 'long',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
    timeZone: 'Europe/Oslo'
});
const MILLISECONDS_PER_MINUTE = 60 * 1000;
const MILLISECONDS_PER_HOUR = 60 * MILLISECONDS_PER_MINUTE;
const MILLISECONDS_PER_DAY = 24 * MILLISECONDS_PER_HOUR;
const MINIMUM_LOADING_DURATION_MS = 1000;

function wait(milliseconds) {
    return new Promise((resolve) => setTimeout(resolve, milliseconds));
}

function threadStatusInTjenesteleverandorContext(status) {
    return status === 'Expired' || status === 'Declined' ? 'Oppdraget er tilbakeført til Nav' : '';
}

function mapThreadToConversation(thread) {
    const threadType = thread.CRM_Thread_Type__c || thread.CRM_Type__c;

    return {
        ...thread,
        id: thread.Id,
        ownerId: thread.OwnerId,
        subject: thread.HOT_Subject__c || '',
        appointmentTime: formatSalesforceDateTime(thread.HOT_AppointmentStartTime__c),
        latestMessageDateTime: thread.CRM_Latest_Message_Datetime__c || thread.CRM_Registered_Datetime_Formula__c,
        isRead: Number(thread.CRM_Number_of_unread_Messages__c || 0) === 0,
        threadType,
        participantLabel: threadType === 'HOT_TJENESTELEVERANDOR-FORMIDLER' ? 'Med Nav' : 'Med tolk',
        relatedRecordId: thread.CRM_Related_Object__c,
        showthreadStatusInTjenesteleverandorContext: threadStatusInTjenesteleverandorContext(
            thread.HOT_ServiceAppointment__r?.HOT_TjenesteleverandorStatus__c
        )
    };
}

function toThreadParticipantLabels(participants, threadType) {
    return participants.map((participant) => ({
        id: participant.userId || participant.name,
        label: participant.role ? `${participant.name} (${participant.role})` : participant.name
    }));
}

function toCounterpartyReadParticipants(participants, threadType) {
    const readers = participants.filter((participant) => {
        if (!participant.hasRead) {
            return false;
        }

        return threadType === 'HOT_TJENESTELEVERANDOR-FORMIDLER'
            ? participant.name === 'Formidler'
            : participant.role === 'Tolk';
    });

    return readers.map((participant) => ({
        id: participant.userId || participant.name,
        label: participant.role ? `${participant.name} (${participant.role})` : participant.name
    }));
}

function getTimestamp(dateTime) {
    const timestamp = Date.parse(dateTime);
    return Number.isNaN(timestamp) ? null : timestamp;
}

function formatSalesforceDateTime(dateTime) {
    const timestamp = getTimestamp(dateTime);

    if (timestamp === null) {
        return '';
    }

    const dateParts = Object.fromEntries(
        NORWEGIAN_DATE_TIME_FORMATTER.formatToParts(new Date(timestamp)).map(({ type, value }) => [type, value])
    );

    return `${Number(dateParts.day)} ${dateParts.month} ${dateParts.year}, kl ${dateParts.hour}:${dateParts.minute}`;
}

function formatLatestMessageDateTime(dateTime, currentTimestamp) {
    const timestamp = getTimestamp(dateTime);

    if (timestamp === null) {
        return '';
    }

    const elapsedMilliseconds = currentTimestamp - timestamp;

    if (elapsedMilliseconds >= 0 && elapsedMilliseconds < MILLISECONDS_PER_HOUR) {
        const minutes = Math.max(1, Math.floor(elapsedMilliseconds / MILLISECONDS_PER_MINUTE));
        return `${minutes} ${minutes === 1 ? 'minutt' : 'minutter'} siden`;
    }

    if (elapsedMilliseconds < MILLISECONDS_PER_DAY && elapsedMilliseconds >= MILLISECONDS_PER_HOUR) {
        const hours = Math.floor(elapsedMilliseconds / MILLISECONDS_PER_HOUR);
        return `${hours} ${hours === 1 ? 'time' : 'timer'} siden`;
    }

    return formatSalesforceDateTime(dateTime);
}

function compareConversations(a, b) {
    if (a.isRead !== b.isRead) {
        return a.isRead ? 1 : -1;
    }

    const aTimestamp = getTimestamp(a.latestMessageDateTime);
    const bTimestamp = getTimestamp(b.latestMessageDateTime);

    if (aTimestamp === null || bTimestamp === null) {
        if (aTimestamp === bTimestamp) return 0;
        return aTimestamp === null ? 1 : -1;
    }

    return a.isRead ? bTimestamp - aTimestamp : aTimestamp - bTimestamp;
}
