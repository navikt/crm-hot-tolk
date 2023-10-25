import { LightningElement, wire, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getmessages from '@salesforce/apex/HOT_MessageHelper.getMessagesFromThread';
import markAsRead from '@salesforce/apex/HOT_MessageHelper.markAsRead';
import markThreadAsRead from '@salesforce/apex/HOT_MessageHelper.markThreadAsRead';
import { refreshApex } from '@salesforce/apex';
import getContactId from '@salesforce/apex/HOT_MessageHelper.getUserContactId';
import getRelatedObjectDetails from '@salesforce/apex/HOT_MessageHelper.getRelatedObjectDetails';
import { formatDate } from 'c/datetimeFormatter';
import getServiceAppointmentDetails from '@salesforce/apex/HOT_MyServiceAppointmentListController.getServiceAppointmentDetails';
import getInterestedResourceDetails from '@salesforce/apex/HOT_InterestedResourcesListController.getInterestedResourceDetails';
import getWageClaimDetails from '@salesforce/apex/HOT_WageClaimListController.getWageClaimDetails';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import createmsg from '@salesforce/apex/HOT_MessageHelper.createMessage';
import { getParametersFromURL } from 'c/hot_URIDecoder';

import setLastMessageFrom from '@salesforce/apex/HOT_MessageHelper.setLastMessageFrom';
import { formatRecord } from 'c/datetimeFormatter';

import getThreadDetails from '@salesforce/apex/HOT_ThreadDetailController.getThreadDetails';

export default class hot_messagingCommunityThreadViewer extends NavigationMixin(LightningElement) {
    _mySendForSplitting;
    messages = [];
    buttonisdisabled = false;
    userContactId;
    thread;
    threadRelatedObjectId;
    @track isDetails = false;
    @track isIRDetails = false;
    @track isWCDetails = false;
    @track msgVal;
    @track isFreelance = false;
    @track isclosed;
    @track showContent = false;
    @track hasAccess;

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
            .catch((error) => {
                //Apex error
            });
    }

    @track breadcrumbs = [
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
    @track breadcrumbsFreelance = [
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

    @track subject;
    @track threadType;
    @wire(getThreadDetails, { recordId: '$recordId' })
    wirethreadss(result) {
        if (result.data) {
            this.thread = result.data;
            this.subject = this.thread.HOT_Subject__c;
            this.threadType = this.threadTypeName();
            this.threadRelatedObjectId = this.thread.CRM_Related_Object__c;
            this.isclosed = this.thread.CRM_Is_Closed__c;
            this.showContent = true;
        }
    }

    get showopenwarning() {
        if (this.alertopen) {
            return true;
        }
        return false;
    }

    threadTypeName() {
        var threadTypeValue = this.thread.CRM_Thread_Type__c;
        if (threadTypeValue === 'HOT_BRUKER-FORMIDLER') {
            this.helptextContent =
                'Her kan du sende en melding til tolkeformidlingen som er relevant for din bestilling.  Det du skriver her, kan tolkeformidlere ved din tolketjeneste se.  Meldingen vil bli slettet etter ett år.';
            return '(Samtale med formidler)';
        }
        if (threadTypeValue === 'HOT_BESTILLER-FORMIDLER') {
            this.helptextContent =
                'Her kan du sende en melding til tolkeformidlingen som er relevant for din bestilling.  Det du skriver her, kan tolkeformidlere ved din tolketjeneste se.  Meldingen vil bli slettet etter ett år.';
            return '(Samtale med formidler)';
        }
        if (threadTypeValue === 'HOT_BRUKER-TOLK') {
            if (this.isFreelance == true || this.navigationBaseList != '') {
                this.helptextContent =
                    'Her kan du sende en melding som er relevant for din bestilling.  Det du skriver her, kan tolkeformidlere, NAV-ansatte tolker og eventuelt frilanstolker ved din tolketjeneste se.  Meldingen vil bli slettet etter ett år.';
                return '(Samtale mellom tolk og bruker)';
            } else {
                this.helptextContent =
                    'Her kan du sende en melding som er relevant for din bestilling.  Det du skriver her, kan tolkeformidlere, NAV-ansatte tolker og eventuelt frilanstolker ved din tolketjeneste se.  Meldingen vil bli slettet etter ett år.';
                return '(Samtale med tolk)';
            }
        }
        if (threadTypeValue === 'HOT_BRUKER-BESTILLER') {
            this.helptextContent =
                'Her kan du sende en melding som er relevant for din bestilling.  Det du skriver her, kan tolkeformidlere, bruker og bestiller av bestillingen se.  Meldingen vil bli slettet etter ett år.';
            return '(Samtale mellom bruker og bestiller)';
        }
        if (threadTypeValue === 'HOT_TOLK-FORMIDLER') {
            this.helptextContent =
                'Her kan du sende en melding som er relevant for oppdraget.  Det du skriver her, kan tolkeformidlere ved din tolketjeneste se.  Meldingen vil bli slettet etter ett år.';
            return '(Samtale med formidler)';
        }
        if (threadTypeValue === 'HOT_TOLK-RESSURSKONTOR') {
            this.helptextContent =
                'Her kan du sende en melding som er relevant for oppdraget.  Det du skriver her, kan ressurskontoret ved din tolketjeneste se.  Meldingen vil bli slettet etter ett år.';
            return '(Samtale med ressurskontor)';
        }
        if (threadTypeValue === 'HOT_TOLK-TOLK') {
            this.helptextContent =
                'Her kan du sende en melding som er relevant for oppdraget.  Det du skriver her, kan tolkeformidlere og andre tolker som er tildelt oppdraget ved din tolketjeneste se.  Meldingen vil bli slettet etter ett år.';
            return '(Samtale med medtolker)';
        }
        return threadTypeValue;
    }
    get isHelpText() {
        return this.helptextContent !== '' && this.helptextContent !== undefined ? true : false;
    }

    @wire(getmessages, { threadId: '$recordId' }) //Calls apex and extracts messages related to this record
    wiremessages(result) {
        this._mySendForSplitting = result;
        if (result.error) {
            this.error = result.error;
        } else if (result.data) {
            this.messages = result.data;
            this.showspinner = false;
        }
    }

    /**
     * Blanks out all text fields, and enables the submit-button again.
     * @Author lars Petter Johnsen
     */
    handlesuccess() {
        const inputFields = this.template.querySelectorAll('.msgText');
        if (inputFields) {
            inputFields.forEach((field) => {
                field.reset();
            });
        }
        const textBoks = this.template.querySelector('c-hot_community-textarea');
        textBoks.clearText();
        this.buttonisdisabled = false;
        return refreshApex(this._mySendForSplitting);
    }

    handleMessageFailed() {
        this.buttonisdisabled = true;
        refreshApex(this._mySendForSplitting);
        // eslint-disable-next-line @lwc/lwc/no-api-reassignments
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

    /**
     * Creates a message through apex
     */
    @api
    createMessage(validation) {
        if (validation !== true) {
            this.buttonisdisabled = false;
            return;
        }
        createmsg({ threadId: this.recordId, messageText: this.msgVal, fromContactId: this.userContactId })
            .then((result) => {
                if (result === true) {
                    setLastMessageFrom({ threadId: this.recordId, fromContactId: this.userContactId });
                    this.handlesuccess();
                } else {
                    this.handleMessageFailed();
                }
            })
            .catch((error) => console.log(error));
    }

    handleSendButtonClick() {
        this.buttonisdisabled = true;
        // Sending out event to parent to handle any needed validation
        if (this.overrideValidation === true) {
            const validationEvent = new CustomEvent('validationevent', {
                msg: this.msgVal,
                maxLength: this.maxLength
            });
            this.dispatchEvent(validationEvent);
        } else {
            // Using default validation
            this.createMessage(this.valid());
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

    goBack() {
        if (this.navigationBaseUrl == 'mine-oppdrag') {
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    pageName: this.navigationBaseUrl
                },
                state: {
                    list: this.navigationBaseList,
                    id: this.navigationId
                }
            });
        } else if (this.navigationBaseUrl == 'mine-samtaler-frilanstolk') {
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    pageName: 'mine-samtaler-frilanstolk'
                },
                state: {}
            });
        } else if (this.navigationBaseUrl == 'mine-samtaler') {
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    pageName: 'mine-samtaler'
                },
                state: {}
            });
        } else if ((this.navigationBaseUrl = 'mine-varsler')) {
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    pageName: 'mine-varsler'
                },
                state: {}
            });
        } else {
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    pageName: this.navigationBaseUrl
                },
                state: {
                    id: this.navigationId,
                    level: this.navigationLevel
                }
            });
        }
    }
    closeModal() {
        this.template.querySelector('.serviceAppointmentDetails').classList.add('hidden');
    }
    @track serviceAppointment;
    @track interestedResource;

    goToDetails() {
        let i = 0;
        getRelatedObjectDetails({ relatedRecordId: this.threadRelatedObjectId }).then((result) => {
            for (var key in result) {
                i++;
                if (result[key] == 'SA') {
                    this.interestedResource = false;
                    getInterestedResourceDetails({ recordId: key }).then((result) => {
                        this.interestedResource = result;
                    });
                    getServiceAppointmentDetails({ recordId: key }).then((result) => {
                        this.serviceAppointment = result;
                        let startTimeFormatted = new Date(result.EarliestStartTime);
                        let endTimeFormatted = new Date(result.DueDate);
                        this.serviceAppointment.StartAndEndDate =
                            startTimeFormatted.getDate() +
                            '.' +
                            (startTimeFormatted.getMonth() + 1) +
                            '.' +
                            startTimeFormatted.getFullYear() +
                            ', ' +
                            ('0' + startTimeFormatted.getHours()).substr(-2) +
                            ':' +
                            ('0' + startTimeFormatted.getMinutes()).substr(-2) +
                            ' - ' +
                            ('0' + endTimeFormatted.getHours()).substr(-2) +
                            ':' +
                            ('0' + endTimeFormatted.getMinutes()).substr(-2);
                        let actualstartTimeFormatted = new Date(result.ActualStartTime);
                        let actualendTimeFormatted = new Date(result.ActualEndTime);
                        this.serviceAppointment.ActualStartTime =
                            actualstartTimeFormatted.getDate() +
                            '.' +
                            (actualstartTimeFormatted.getMonth() + 1) +
                            '.' +
                            actualstartTimeFormatted.getFullYear() +
                            ' ' +
                            ('0' + actualstartTimeFormatted.getHours()).substr(-2) +
                            ':' +
                            ('0' + actualstartTimeFormatted.getMinutes()).substr(-2);
                        this.serviceAppointment.ActualEndTime =
                            actualendTimeFormatted.getDate() +
                            '.' +
                            (actualendTimeFormatted.getMonth() + 1) +
                            '.' +
                            actualendTimeFormatted.getFullYear() +
                            ' ' +
                            ('0' + actualendTimeFormatted.getHours()).substr(-2) +
                            ':' +
                            ('0' + actualendTimeFormatted.getMinutes()).substr(-2);
                        if (this.serviceAppointment.ActualStartTime.includes('NaN')) {
                            this.serviceAppointment.ActualStartTime = '';
                        }
                        if (this.serviceAppointment.ActualEndTime.includes('NaN')) {
                            this.serviceAppointment.ActualEndTime = '';
                        }
                        this.isDetails = true;
                        this.template.querySelector('.serviceAppointmentDetails').classList.remove('hidden');
                    });
                    break;
                }
                if (result[key] == 'IR') {
                    getInterestedResourceDetails({ recordId: key }).then((result) => {
                        this.interestedResource = result;
                        let startTimeFormatted = new Date(result.ServiceAppointmentStartTime__c);
                        let endTimeFormatted = new Date(result.ServiceAppointmentEndTime__c);
                        this.interestedResource.StartAndEndDate =
                            startTimeFormatted.getDate() +
                            '.' +
                            (startTimeFormatted.getMonth() + 1) +
                            '.' +
                            startTimeFormatted.getFullYear() +
                            ', ' +
                            ('0' + startTimeFormatted.getHours()).substr(-2) +
                            ':' +
                            ('0' + startTimeFormatted.getMinutes()).substr(-2) +
                            ' - ' +
                            ('0' + endTimeFormatted.getHours()).substr(-2) +
                            ':' +
                            ('0' + endTimeFormatted.getMinutes()).substr(-2);
                        let DeadlineDateTimeFormatted = new Date(this.interestedResource.AppointmentDeadlineDate__c);
                        this.interestedResource.AppointmentDeadlineDate__c =
                            DeadlineDateTimeFormatted.getDate() +
                            '.' +
                            (DeadlineDateTimeFormatted.getMonth() + 1) +
                            '.' +
                            DeadlineDateTimeFormatted.getFullYear();
                        if (this.interestedResource.AppointmentDeadlineDate__c.includes('NaN')) {
                            this.interestedResource.AppointmentDeadlineDate__c = '';
                        }
                        this.isIRDetails = true;
                        this.template.querySelector('.serviceAppointmentDetails').classList.remove('hidden');
                    });

                    break;
                }
                if (result[key] == 'WC') {
                    getWageClaimDetails({ recordId: key }).then((result) => {
                        this.wageClaim = result;
                        let startTimeFormatted = new Date(this.wageClaim.StartTime__c);
                        let endTimeFormatted = new Date(this.wageClaim.EndTime__c);
                        this.wageClaim.StartAndEndDate =
                            startTimeFormatted.getDate() +
                            '.' +
                            (startTimeFormatted.getMonth() + 1) +
                            '.' +
                            startTimeFormatted.getFullYear() +
                            ', ' +
                            ('0' + startTimeFormatted.getHours()).substr(-2) +
                            ':' +
                            ('0' + startTimeFormatted.getMinutes()).substr(-2) +
                            ' - ' +
                            ('0' + endTimeFormatted.getHours()).substr(-2) +
                            ':' +
                            ('0' + endTimeFormatted.getMinutes()).substr(-2);
                        this.isWCDetails = true;
                        this.template.querySelector('.serviceAppointmentDetails').classList.remove('hidden');
                    });

                    break;
                }
                if (result[key] == 'Andre-WO') {
                    this[NavigationMixin.Navigate]({
                        type: 'comm__namedPage',
                        attributes: {
                            pageName: 'mine-bestillinger-andre'
                        },
                        state: {
                            id: key,
                            level: 'WO'
                        }
                    });
                    break;
                }
                if (result[key] == 'Andre-R') {
                    this[NavigationMixin.Navigate]({
                        type: 'comm__namedPage',
                        attributes: {
                            pageName: 'mine-bestillinger-andre'
                        },
                        state: {
                            id: key,
                            level: 'R'
                        }
                    });
                    break;
                } else {
                    this[NavigationMixin.Navigate]({
                        type: 'comm__namedPage',
                        attributes: {
                            pageName: 'mine-bestillinger'
                        },
                        state: {
                            id: key,
                            level: result[key]
                        }
                    });
                }
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
            parsed_params.from != 'mine-samtaler'
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
