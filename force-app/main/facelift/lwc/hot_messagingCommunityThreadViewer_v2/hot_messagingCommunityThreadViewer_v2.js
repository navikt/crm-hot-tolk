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

    connectedCallback() {}

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
    wirethreads(result) {
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

    get showOpenWarning() {
        if (this.alertopen) {
            return true;
        }
        return false;
    }
}
