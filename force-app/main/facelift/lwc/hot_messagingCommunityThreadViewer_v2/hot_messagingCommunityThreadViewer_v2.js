import { LightningElement, wire, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getmessages from '@salesforce/apex/HOT_MessageHelper.getMessagesFromThread';
import markAsRead from '@salesforce/apex/HOT_MessageHelper.markAsRead';
import markThreadAsRead from '@salesforce/apex/HOT_MessageHelper.markThreadAsRead';
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

import setLastMessageFrom from '@salesforce/apex/HOT_MessageHelper.setLastMessageFrom';
import { formatRecord } from 'c/datetimeFormatterNorwegianTime';

import getThreadDetails from '@salesforce/apex/HOT_ThreadDetailController.getThreadDetails';

export default class Hot_messagingCommunityThreadViewer_v2 extends NavigationMixin(LightningElement) {
    _mySendForSplitting;
    messages = [];
    buttonisdisabled = false;
    userContactId;
    thread;
    threadRelatedObjectId;

    isDetails = false;
    isIRDetails = false;
    isWCDetails = false;
    msgVal;
    isFreelance = false;
    isclosed;
    showContent = false;
    showError = false;
    hasAccess;

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
        // this.getParams();
        getContactId({})
            .then((contactId) => {
                this.userContactId = contactId;
                refreshApex(this._mySendForSplitting);
                markThreadAsRead({ threadId: this.recordId, userContactId: this.userContactId });
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
        if (result.data) {
            this.thread = result.data;
            this.subject = this.thread.HOT_Subject__c;
            // this.threadType = this.threadTypeName();
            this.threadRelatedObjectId = this.thread.CRM_Related_Object__c;
            this.isclosed = this.thread.CRM_Is_Closed__c;
            this.showContent = true;
        } else if (result.error) {
            this.showError = true;
        }
    }

    // Calls apex and extracts messages related to this record
    @wire(getmessages, { threadId: '$recordId' })
    wireMessages(result) {
        this._mySendForSplitting = result;
        if (result.error) {
            this.error = result.error;
        } else if (result.data) {
            this.messages = result.data;
            this.showspinner = false;
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

    serviceAppointment;
    interestedResource;
    address;
    ordererPhoneNumber;
    accountPhoneNumber;
    accountAgeGender;
    accountName;

    closeModal() {
        this.template.querySelector('.serviceAppointmentDetails').classList.add('hidden');
    }

    goToHome() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                pageName: 'home'
            }
        });
    }

    // Set helptextContent based on type and return label
    threadTypeName() {
        const threadTypeValue = this.thread.CRM_Thread_Type__c;

        switch (threadTypeValue) {
            case 'HOT_BRUKER-FORMIDLER':
            case 'HOT_BESTILLER-FORMIDLER':
                this.helptextContent =
                    'Her kan du sende en melding til tolkeformidlingen som er relevant for din bestilling.  Det du skriver her, kan tolkeformidlere ved din tolketjeneste se.  Meldingen vil bli slettet etter ett år.';
                return '(Samtale med formidler)';

            case 'HOT_BRUKER-TOLK': {
                this.helptextContent =
                    'Her kan du sende en melding som er relevant for din bestilling.  Det du skriver her, kan tolkeformidlere, NAV-ansatte tolker og eventuelt frilanstolker ved din tolketjeneste se.  Meldingen vil bli slettet etter ett år.';
                if (this.isFreelance === true || this.navigationBaseList !== '') {
                    return '(Samtale mellom tolk og bruker)';
                } else {
                    return '(Samtale med tolk)';
                }
            }

            case 'HOT_BRUKER-BESTILLER':
                this.helptextContent =
                    'Her kan du sende en melding som er relevant for din bestilling.  Det du skriver her, kan tolkeformidlere, bruker og bestiller av bestillingen se.  Meldingen vil bli slettet etter ett år.';
                return '(Samtale med formidler';

            case 'HOT_TOLK-FORMIDLER':
                this.helptextContent =
                    'Her kan du sende en melding som er relevant for oppdraget.  Det du skriver her, kan tolkeformidlere ved din tolketjeneste se.  Meldingen vil bli slettet etter ett år.';
                return '(Samtale med formidler)';

            case 'HOT_TOLK-RESSURSKONTOR':
                this.helptextContent =
                    'Her kan du sende en melding som er relevant for oppdraget.  Det du skriver her, kan ressurskontoret ved din tolketjeneste se.  Meldingen vil bli slettet etter ett år.';
                return '(Samtale med ressurskontor)';

            case 'HOT_TOLK-TOLK':
                this.helptextContent =
                    'Her kan du sende en melding som er relevant for oppdraget.  Det du skriver her, kan tolkeformidlere og andre tolker som er tildelt oppdraget ved din tolketjeneste se.  Meldingen vil bli slettet etter ett år.';
                return '(Samtale med medtolker)';

            default:
                return threadTypeValue;
        }
    }

    navigationBaseList = '';

    goToDetails() {
        getRelatedObjectDetails({ relatedRecordId: this.threadRelatedObjectId }).then((result) => {
            for (const [key, type] of Object.defineProperties(result)) {
                switch (type) {
                    case 'SA':

                    case 'IR':

                    case 'WC':

                    default:
                        return;
                }
            }
        });
    }
}
