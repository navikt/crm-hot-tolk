import { LightningElement, wire, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getmessages from '@salesforce/apex/HOT_MessageHelper.getMessagesFromThread';
import markThreadAsRead from '@salesforce/apex/HOT_MessageHelper.markThreadAsRead';
import getThreadParticipants from '@salesforce/apex/HOT_ThreadParticipants.getParticipants';
import { refreshApex } from '@salesforce/apex';
import getContactId from '@salesforce/apex/HOT_MessageHelper.getUserContactId';
import getRelatedObjectDetails from '@salesforce/apex/HOT_MessageHelper.getRelatedObjectDetails';
import { formatDate, formatDatetimeinterval, formatDatetime } from 'c/datetimeFormatterNorwegianTime';
import getServiceAppointmentDetails from '@salesforce/apex/HOT_MyServiceAppointmentListController.getServiceAppointmentDetails';
import getInterestedResourceDetails from '@salesforce/apex/HOT_InterestedResourcesListController.getInterestedResourceDetails';
import getWageClaimDetails from '@salesforce/apex/HOT_WageClaimListController.getWageClaimDetails';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import createmsg from '@salesforce/apex/HOT_MessageHelper.createMessage';
import { getParametersFromURL } from 'c/hot_URIDecoder';
import icons from '@salesforce/resourceUrl/ikoner';

import buildReadByEntriesForThread from '@salesforce/apex/HOT_MessageHelper.buildReadByEntriesForThread';
import USER_ID from '@salesforce/user/Id';
import setLastMessageFrom from '@salesforce/apex/HOT_MessageHelper.setLastMessageFrom';
import { formatRecord } from 'c/datetimeFormatterNorwegianTime';

import getThreadDetails from '@salesforce/apex/HOT_ThreadDetailController.getThreadDetails';
export default class Hot_messagingCommunityThreadViewer_v2 extends NavigationMixin(LightningElement) {
    exitCrossIcon = icons + '/Close/Close.svg';
    _mySendForSplitting;
    messages = [];
    buttonisdisabled = false;
    userContactId;
    thread;
    threadRelatedObjectId;

    _threadWire;

    isDetails = false;
    isDetailsContent = false;
    isIRDetails = false;
    isWCDetails = false;
    msgVal;
    isFreelance = false;
    isclosed;
    showContent = false;
    showError = false;
    readByText = '';
    showReadBy = false;
    hasAccess = true;

    latestSenderContactId;
    latestSenderUserId;
    hideReadBy = false;
    isLoading = false;
    buttonLoading = false;

    @api recordId;
    @api requestId;
    @api alerttext;
    @api header;
    @api secondheader;
    @api alertopen;
    @api maxLength;
    @api overrideValidation = false;
    @api errorList = { title: '', errors: [] };
    @api helptextContent;
    @api helptextHovertext;

    connectedCallback() {
        this.getParams();

        getContactId({})
            .then((contactId) => {
                this.userContactId = contactId;
                refreshApex(this._mySendForSplitting);
                markThreadAsRead({ threadId: this.recordId, userContactId: this.userContactId });
            })
            .then(() => {
                // Just refresh the messages wire to get updated names
                if (this._mySendForSplitting) {
                    return refreshApex(this._mySendForSplitting);
                }
            })
            .then(() => {
                if (this._mySendForSplitting) {
                    return refreshApex(this._mySendForSplitting);
                }
            })
            .then(() => {
                // Ensure read-by reflects any server-side updates from markThreadAsRead
                return this.ReadByNames();
            })
            .catch((error) => {
                console.error('Error fetching user contact ID:', error);
            });
    }

    openGoogleMaps() {
        window.open('https://www.google.com/maps/search/?api=1&query=' + this.address);
    }
    openAppleMaps() {
        window.open('http://maps.apple.com/?q=' + this.address);
    }

    breadcrumbs = [
        {
            label: 'Tolketjenesten',
            href: ''
        },
        {
            label: 'Mine samtaler',
            href: 'mine-samtaler'
        },
        {
            label: 'Min samtale',
            href: 'detail'
        }
    ];

    breadcrumbsFreelance = [
        {
            label: 'Tolketjenesten',
            href: ''
        },
        {
            label: 'Mine samtaler som frilanstolk',
            href: 's/mine-samtaler-frilanstolk'
        },
        {
            label: 'Min samtale',
            href: 'detail'
        }
    ];

    subject;
    threadType;
    @wire(getThreadDetails, { recordId: '$recordId' })
    wireThreads(result) {
        this._threadWire = result;
        if (result.data) {
            this.thread = result.data;
            this.subject = this.thread.HOT_Subject__c;
            this.threadType = this.threadTypeName();
            this.threadRelatedObjectId = this.thread.CRM_Related_Object__c;
            this.isclosed = this.thread.CRM_Is_Closed__c;
            this.showContent = true;

            this.ReadByNames();
        } else if (result.error) {
            this.showError = true;
        }
    }

    formatName(value) {
        if (!value) return '';
        const s = String(value).trim();
        return s
            .toLocaleLowerCase('nb-NO')
            .replace(/(^|[\s\-'])(\p{L})/gu, (m, p1, p2) => p1 + p2.toLocaleUpperCase('nb-NO'));
    }

    async ReadByNames() {
        if (this.hideReadBy) {
            this.showReadBy = false;
            this.readByText = '';
            return;
        }

        if (!this.userContactId || !this.recordId) {
            this.showReadBy = false;
            this.readByText = '';
            return;
        }

        try {
            const entries = await buildReadByEntriesForThread({ threadId: this.recordId });

            const labels = [];
            const seen = new Set();

            for (const e of entries || []) {
                if (!e) continue;

                if (e.threadId && (e.threadId === this.userContactId || e.threadId === USER_ID)) {
                    continue;
                }
                if (
                    e.threadId &&
                    (e.threadId === this.latestSenderContactId || e.threadId === this.latestSenderUserId)
                ) {
                    continue;
                }

                const label = e.isFormidlerRole ? 'Formidler' : e.displayName;
                if (!label) continue;

                const key = label.trim().toLowerCase();
                if (seen.has(key)) continue;
                seen.add(key);
                labels.push(this.formatName(label));
            }

            this.showReadBy = labels.length > 0;
            this.readByText = labels.join(', ');
        } catch (e) {
            console.error('buildReadByEntriesForThread failed', e);
            this.showReadBy = false;
            this.readByText = '';
        }
    }

    get readByNames() {
        return this.showReadBy ? this.readByText : '';
    }

    get isContentReady() {
        return this.showContent && this._threadWire?.data && this._mySendForSplitting?.data && this.userContactId;
    }

    // Calls apex and extracts messages related to this record
    @wire(getmessages, { threadId: '$recordId' })
    wireMessages(result) {
        this._mySendForSplitting = result;
        if (result.error) {
            console.log('Error retrieving messages: ', result.error);
            this.error = result.error;
        } else if (result.data) {
            this.messages = result.data;
            this.showScrollButton = this.messages.length > 0;

            // figure out latest sender (supports user and contact)
            const last = this.messages && this.messages.length ? this.messages[this.messages.length - 1] : null;
            this.latestSenderContactId = last ? last.CRM_From_Contact__c : undefined;
            this.latestSenderUserId = last ? last.CRM_From_User__c : undefined;

            const latestFromMe =
                (this.latestSenderContactId &&
                    this.userContactId &&
                    this.latestSenderContactId === this.userContactId) ||
                (this.latestSenderUserId && USER_ID && this.latestSenderUserId === USER_ID);

            if (this.hideReadBy && !latestFromMe) {
                this.hideReadBy = false;
            }

            this.showspinner = false;
            this.ReadByNames();
        }
    }

    get showOpenWarning() {
        if (this.alertopen) {
            return true;
        }
        return false;
    }

    get isHelpText() {
        return this.helptextContent !== '' && this.helptextContent !== undefined ? true : false;
    }

    get participantList() {
        if (!this.readByText) return [];
        return this.readByText
            .split(',')
            .map((name) => name.trim())
            .filter((name) => name);
    }

    scrollToLatestMessage() {
        const messageContainers = this.template.querySelectorAll('c-hot_messaging-Community-Message-Container_v2');

        if (messageContainers && messageContainers.length > 0) {
            const lastMessage = messageContainers[messageContainers.length - 1];
            lastMessage.scrollIntoView({ behavior: 'smooth', block: 'start' });
            lastMessage.focus();
        }
    }

    threadParticipants = [];

    handleShowParticipants() {
        this.isLoading = true;
        this.showParticipantsModalDetails();
        getThreadParticipants({ threadId: this.recordId })
            .then((result) => {
                this.threadParticipants = result; // lagrer deltakerne
                this.isLoading = false;
            })
            .catch((error) => {
                console.error(error);
            });
    }

    closeModal() {
        const dialogModalSA = this.template.querySelector('.modal-service-appointment');
        dialogModalSA.close();

        const dialogParticipants = this.template.querySelector('.modal-participants');
        dialogParticipants.close();

        this.isDetails = false;
        this.isIRDetails = false;
        this.isWCDetails = false;
        this.isDetailsContent = false;
    }

    goToHome() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                pageName: 'home'
            }
        });
    }

    showParticipantsModalDetails() {
        const dialog = this.template.querySelector('.modal-participants');
        dialog.showModal();
        dialog.focus();
    }

    showServiceAppointmentDetails() {
        const dialog = this.template.querySelector('.modal-service-appointment');
        dialog.showModal();
        dialog.focus();
    }

    // Set helptextContent based on type and return label
    threadTypeName() {
        var threadTypeValue = this.thread.CRM_Thread_Type__c;

        switch (threadTypeValue) {
            case 'HOT_BRUKER-FORMIDLER':
            case 'HOT_BESTILLER-FORMIDLER':
                this.helptextContent =
                    'Her kan du sende en melding til tolkeformidlingen som er relevant for din bestilling.  Det du skriver her, kan tolkeformidlere ved din tolketjeneste se.  Meldingen vil bli slettet etter ett år.';
                return 'Samtale med formidler';

            case 'HOT_BRUKER-TOLK': {
                this.helptextContent =
                    'Her kan du sende en melding som er relevant for din bestilling.  Det du skriver her, kan tolkeformidlere, NAV-ansatte tolker og eventuelt frilanstolker ved din tolketjeneste se.  Meldingen vil bli slettet etter ett år.';
                if (this.isFreelance === true || this.navigationBaseList !== '') {
                    return 'Samtale mellom tolk og bruker';
                } else {
                    return 'Samtale med tolk';
                }
            }

            case 'HOT_BRUKER-BESTILLER':
                this.helptextContent =
                    'Her kan du sende en melding som er relevant for din bestilling.  Det du skriver her, kan tolkeformidlere, bruker og bestiller av bestillingen se.  Meldingen vil bli slettet etter ett år.';
                return 'Samtale med formidler';

            case 'HOT_TOLK-FORMIDLER':
                this.helptextContent =
                    'Her kan du sende en melding som er relevant for oppdraget.  Det du skriver her, kan tolkeformidlere ved din tolketjeneste se.  Meldingen vil bli slettet etter ett år.';
                return 'Samtale med formidler';

            case 'HOT_TOLK-RESSURSKONTOR':
                this.helptextContent =
                    'Her kan du sende en melding som er relevant for oppdraget.  Det du skriver her, kan ressurskontoret ved din tolketjeneste se.  Meldingen vil bli slettet etter ett år.';
                return 'Samtale med ressurskontor';

            case 'HOT_TOLK-TOLK':
                this.helptextContent =
                    'Her kan du sende en melding som er relevant for oppdraget.  Det du skriver her, kan tolkeformidlere og andre tolker som er tildelt oppdraget ved din tolketjeneste se.  Meldingen vil bli slettet etter ett år.';
                return 'Samtale med medtolker';

            default:
                return threadTypeValue;
        }
    }

    handleSuccess() {
        this.template.querySelector('c-textarea').setTextValue('');
        this.msgVal = '';
        this.buttonisdisabled = false;

        this.hideReadBy = true;
        this.showReadBy = false;
        this.readByText = '';

        try {
            Promise.all([refreshApex(this._mySendForSplitting), refreshApex(this._threadWire)]);
        } catch (e) {
            console.error('refresh after send failed', e);
        }
    }

    handleMessageFailed() {
        this.buttonisdisabled = true;
        refreshApex(this._mySendForSplitting);
        this.errorList = {
            title: 'Denne samtalen har blitt avsluttet.',
            errors: [
                {
                    Id: 1,
                    EventItem: '',
                    Text: 'Vil du <a href="https://www.nav.no/person/kontakt-oss/nb/skriv-til-oss">sende en ny melding</a>, kan du gjøre det her. Husk å kopiere det du har skrevet.'
                }
            ]
        };
        let errorSummary = this.template.querySelector('.errorSummary');
        errorSummary.focusHeader();
    }

    @api
    createMessage(validation) {
        if (validation !== true) {
            this.buttonisdisabled = false;
            this.buttonLoading = false;
            return;
        }
        this.buttonLoading = true;

        createmsg({ threadId: this.recordId, messageText: this.msgVal, fromContactId: this.userContactId })
            .then((result) => {
                if (result === true) {
                    setLastMessageFrom({ threadId: this.recordId, fromContactId: this.userContactId });
                    this.handleSuccess();
                } else {
                    this.handleMessageFailed();
                }
            })
            .catch((error) => console.log(error))
            .finally(() => {
                this.buttonLoading = false;
            });
    }

    handleSendButtonClick() {
        this.buttonisdisabled = true;
        this.hideReadBy = true;
        this.showReadBy = false;
        this.readByText = '';

        if (this.overrideValidation === true) {
            this.buttonLoading = true;
            const validationEvent = new CustomEvent('validationevent', {
                msg: this.msgVal,
                maxLength: this.maxLength
            });
            this.dispatchEvent(validationEvent);
        } else {
            // Using default validation
            const isValid = this.valid();
            if (!isValid) {
                this.buttonisdisabled = false;
                this.buttonLoading = false;
                return;
            }

            this.buttonLoading = true;
            this.createMessage(true);
        }
    }

    valid() {
        // This function will never run of errorList is defined from parent with overrideValidation
        // eslint-disable-next-line @lwc/lwc/no-api-reassignments
        this.errorList = { title: '', errors: [] };
        if (!this.msgVal || this.msgVal.length == null) {
            this.errorList.errors.push({ Id: 1, EventItem: '.inputTextbox', Text: 'Tekstboksen kan ikke være tom.' });
        } else if (this.maxLength !== 0 && this.maxLength != null && this.msgVal.length > this.maxLength) {
            this.errorList.errors.push({
                Id: 2,
                EventItem: '.inputTextbox',
                Text: 'Det er for mange tegn i tekstboksen.'
            });
        } else {
            return true;
        }
        let errorSummary = this.template.querySelector('.errorSummary');
        errorSummary.focusHeader();
        return false;
    }

    handleTextChange(event) {
        this.msgVal = event.detail;
    }

    handleErrorClick(event) {
        let item = this.template.querySelector(event.detail);
        item.focus();
    }

    serviceAppointment;
    interestedResource;
    address;
    ordererPhoneNumber;
    isOtherProvider;
    accountPhoneNumber;
    accountAgeGender;
    accountName;

    yesOrNo(boolean) {
        if (boolean) {
            return 'Ja';
        } else {
            return 'Nei';
        }
    }

    goToDetails() {
        this.isLoading = true;
        this.showServiceAppointmentDetails();
        getRelatedObjectDetails({ relatedRecordId: this.threadRelatedObjectId }).then((result) => {
            for (var key in result) {
                let type = result[key];
                switch (type) {
                    case 'SA':
                        this.accountPhoneNumber = '';
                        this.accountAgeGender = '';
                        this.accountName = '';
                        this.ordererPhoneNumber = '';
                        this.isOtherProvider = '';
                        this.interestedResource = false;

                        getInterestedResourceDetails({ recordId: key }).then((result) => {
                            this.interestedResource = result;
                        });

                        getServiceAppointmentDetails({ recordId: key }).then((result) => {
                            this.serviceAppointment = result;
                            this.address = this.serviceAppointment.HOT_AddressFormated__c;
                            this.serviceAppointment.StartAndEndDate = formatDatetimeinterval(
                                result.EarliestStartTime,
                                result.DueDate
                            );
                            this.serviceAppointment.ActualStartTime = formatDatetime(result.ActualStartTime);
                            this.serviceAppointment.ActualEndTime = formatDatetime(result.ActualEndTime);
                            this.serviceAppointment.HOT_HapticCommunication__c = this.yesOrNo(
                                this.serviceAppointment.HOT_HapticCommunication__c
                            );
                            if (
                                this.serviceAppointment &&
                                this.serviceAppointment.HOT_Request__r &&
                                this.serviceAppointment.HOT_Request__r.Account__r.Name
                            ) {
                                this.accountName = this.serviceAppointment.HOT_Request__r.Account__r.Name;
                            }

                            if (
                                this.serviceAppointment &&
                                this.serviceAppointment.HOT_Request__r &&
                                this.serviceAppointment.HOT_Request__r.Account__r &&
                                this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r
                            ) {
                                if (
                                    this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r.CRM_AgeNumber__c ==
                                    undefined
                                ) {
                                    if (
                                        this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r.INT_Sex__c !==
                                        undefined
                                    ) {
                                        this.accountAgeGender =
                                            this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r.INT_Sex__c;
                                    }
                                } else if (
                                    this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r.INT_Sex__c ==
                                    undefined
                                ) {
                                    if (
                                        this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r
                                            .CRM_AgeNumber__c !== undefined
                                    ) {
                                        this.accountAgeGender =
                                            this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r
                                                .CRM_AgeNumber__c + ' år';
                                    }
                                } else if (
                                    this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r.INT_Sex__c !==
                                        undefined &&
                                    this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r.CRM_AgeNumber__c !==
                                        undefined
                                ) {
                                    this.accountAgeGender =
                                        this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r.INT_Sex__c +
                                        ' ' +
                                        this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r
                                            .CRM_AgeNumber__c +
                                        ' år';
                                }
                                if (
                                    this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r
                                        .INT_KrrMobilePhone__c !== undefined
                                ) {
                                    this.accountPhoneNumber =
                                        this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r.INT_KrrMobilePhone__c;
                                }
                            }
                            if (
                                this.serviceAppointment &&
                                this.serviceAppointment.HOT_Request__r &&
                                this.serviceAppointment.HOT_Request__r.Orderer__r &&
                                this.serviceAppointment.HOT_Request__r.Orderer__r.CRM_Person__r
                            ) {
                                if (
                                    this.serviceAppointment.HOT_Request__r.Orderer__r.CRM_Person__r
                                        .INT_KrrMobilePhone__c !== undefined
                                ) {
                                    this.ordererPhoneNumber =
                                        this.serviceAppointment.HOT_Request__r.Orderer__r.CRM_Person__r.INT_KrrMobilePhone__c;
                                }
                            }
                            this.isOtherProvider = this.serviceAppointment.HOT_Request__r.IsOtherEconomicProvicer__c
                                ? 'Ja'
                                : 'Nei';
                            this.isDetailsContent = true;
                            this.isDetails = true;
                            this.hasAccess = true;
                            this.isLoading = false;
                        });
                        break;

                    case 'IR':
                        getInterestedResourceDetails({ recordId: key }).then((result) => {
                            this.interestedResource = result;
                            this.interestedResource.StartAndEndDate = formatDatetimeinterval(
                                result.ServiceAppointmentStartTime__c,
                                result.ServiceAppointmentEndTime__c
                            );
                            let DeadlineDateTimeFormatted = new Date(
                                this.interestedResource.AppointmentDeadlineDate__c
                            );
                            this.interestedResource.AppointmentDeadlineDate__c =
                                DeadlineDateTimeFormatted.getDate() +
                                '.' +
                                (DeadlineDateTimeFormatted.getMonth() + 1) +
                                '.' +
                                DeadlineDateTimeFormatted.getFullYear();
                            let releaseDateTimeFormatted = new Date(
                                this.interestedResource.ServiceAppointment__r.HOT_ReleaseDate__c
                            );
                            this.interestedResource.ServiceAppointment__r.HOT_ReleaseDate__c =
                                releaseDateTimeFormatted.getDate() +
                                '.' +
                                (releaseDateTimeFormatted.getMonth() + 1) +
                                '.' +
                                releaseDateTimeFormatted.getFullYear();
                            this.isDetailsContent = true;
                            this.isIRDetails = true;
                            this.hasAccess = true;
                            this.isLoading = false;
                        });
                        break;

                    case 'WC':
                        getWageClaimDetails({ recordId: key }).then((result) => {
                            this.wageClaim = result;
                            this.wageClaim.StartAndEndDate = formatDatetimeinterval(
                                this.wageClaim.StartTime__c,
                                this.wageClaim.EndTime__c
                            );
                            this.isDetailsContent = true;
                            this.isWCDetails = true;
                            this.hasAccess = true;
                            this.isLoading = false;
                        });
                        break;

                    case 'Andre-WO':
                        this[NavigationMixin.Navigate]({
                            type: 'comm__namedPage',
                            attributes: {
                                pageName: 'mine-bestillinger-andre'
                            },
                            state: {
                                id: key,
                                level: 'WO',
                                from: 'mine-samtaler'
                            }
                        });
                        break;

                    case 'Andre-R':
                        this[NavigationMixin.Navigate]({
                            type: 'comm__namedPage',
                            attributes: {
                                pageName: 'mine-bestillinger-andre'
                            },
                            state: {
                                id: key,
                                level: 'R',
                                from: 'mine-samtaler'
                            }
                        });
                        break;

                    default:
                        this[NavigationMixin.Navigate]({
                            type: 'comm__namedPage',
                            attributes: { pageName: 'mine-bestillinger' },
                            state: { id: key, level: type, from: 'mine-samtaler' }
                        });
                }
                break;
            }
        });
    }

    navigationId = '';
    navigationLevel = '';
    navigationBaseUrl = '';
    navigationBaseList = '';

    getParams() {
        let parsed_params = getParametersFromURL() ?? '';
        if (
            parsed_params.from != 'mine-bestillinger' &&
            parsed_params.from != 'mine-bestillinger-andre' &&
            parsed_params.from != 'mine-samtaler' &&
            parsed_params.from != 'mine-varsler-tolkebruker'
        ) {
            this.recordId = parsed_params.recordId;
        }
        if (parsed_params.recordId !== undefined && parsed_params.level !== undefined) {
            if (parsed_params.from != 'mine-bestillinger-andre') {
                this.navigationBaseUrl = parsed_params.from;
                this.navigationId = parsed_params.recordId;
                this.navigationLevel = parsed_params.level;
                this.breadcrumbs[1] = {
                    label: 'Mine bestillinger',
                    href: 'mine-bestillinger'
                };
            } else {
                this.navigationBaseUrl = parsed_params.from;
                this.navigationId = parsed_params.recordId;
                this.navigationLevel = parsed_params.level;
                this.breadcrumbs[1] = {
                    label: 'Bestillinger på vegne av andre',
                    href: 'mine-bestillinger-andre'
                };
            }
        } else if (parsed_params.from == 'mine-samtaler-frilanstolk') {
            this.navigationBaseUrl = 'mine-samtaler-frilanstolk';
            this.isFreelance = true;
        } else if (parsed_params.from == 'mine-varsler') {
            this.navigationBaseUrl = 'mine-varsler';
            this.isFreelance = true;
        } else if (parsed_params.from == 'mine-varsler-tolkebruker') {
            this.navigationBaseUrl = 'mine-varsler-tolkebruker';
        } else if (parsed_params.from == 'kalender') {
            this.navigationBaseUrl = 'kalender';
        } else if (parsed_params.list !== undefined) {
            this.navigationBaseUrl = parsed_params.from;
            this.navigationId = parsed_params.recordId;
            this.navigationBaseList = parsed_params.list;
            this.navigationLevel = undefined;
            if (parsed_params.list == 'interested') {
                this.breadcrumbs[1] = {
                    label: 'Påmeldte oppdrag',
                    href: 's/mine-oppdrag?list=' + parsed_params.list
                };
            }
            if (parsed_params.list == 'my') {
                this.breadcrumbs[1] = {
                    label: 'Mine oppdrag',
                    href: 's/mine-oppdrag?list=' + parsed_params.list
                };
            }
            if (parsed_params.list == 'wageClaim') {
                this.breadcrumbs[1] = {
                    label: 'Ledig på lønn',
                    href: 's/mine-oppdrag?list=' + parsed_params.list
                };
            }
        } else {
            this.navigationBaseUrl = 'mine-samtaler';
        }
    }
}
