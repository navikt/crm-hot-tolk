import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import { subscribe, unsubscribe } from 'lightning/empApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import ACTIVE_FIELD from '@salesforce/schema/Thread__c.CRM_isActive__c';
import CREATED_BY_FIELD from '@salesforce/schema/Thread__c.CreatedById';
import REGISTERED_DATE from '@salesforce/schema/Thread__c.CRM_Date_Time_Registered__c';
import FIRSTNAME_FIELD from '@salesforce/schema/Thread__c.CreatedBy.FirstName';
import LASTNAME_FIELD from '@salesforce/schema/Thread__c.CreatedBy.LastName';

import getmessages from '@salesforce/apex/CRM_MessageHelper.getMessagesFromThread';
export default class CrmMessagingRedactThreadViewer extends LightningElement {
    @api recordId;
    messages = [];
    _mySendForSplitting;
    @track redactAll = false;

    connectedCallback() {
        this.handleSubscribe();
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

    @wire(getRecord, {
        recordId: '$recordId',
        fields: [ACTIVE_FIELD, CREATED_BY_FIELD, FIRSTNAME_FIELD, LASTNAME_FIELD, REGISTERED_DATE]
    })
    wiredThread;

    get firstname() {
        return getFieldValue(this.wiredThread.data, FIRSTNAME_FIELD);
    }
    get lastname() {
        return getFieldValue(this.wiredThread.data, LASTNAME_FIELD);
    }
    get registereddate() {
        return getFieldValue(this.wiredThread.data, REGISTERED_DATE);
    }

    refreshMessages() {
        return refreshApex(this._mySendForSplitting);
    }

    //Handles subscription to streaming API for listening to changes to auth status
    handleSubscribe() {
        let _this = this;
        // Callback invoked whenever a new message event is received
        const messageCallback = function (response) {
            const messageThreadId = response.data.sobject.CRM_Thread__c;
            if (_this.recordId === messageThreadId) {
                //Refreshes the message in the component if the new message event is for the viewed thread
                _this.refreshMessages();
            }
        };

        // Invoke subscribe method of empApi. Pass reference to messageCallback
        subscribe('/topic/Thread_New_Message', -1, messageCallback).then((response) => {
            // Response contains the subscription information on successful subscribe call
            this.subscription = response;
        });
    }

    handleUnsubscribe() {
        unsubscribe(this.subscription, (response) => {
            // Response is true for successful unsubscribe
        })
            .then((success) => {
                //Successfull unsubscribe
            })
            .catch((error) => {
                console.log('EMP unsubscribe failed: ' + JSON.stringify(error, null, 2));
            });
    }

    handleRedactAllClick(event) {
        this.redactAll = event.detail;
        this.dispatchEvent(
            new ShowToastEvent({
                title: '',
                message: 'Husk å lagre endringer!',
                variant: 'warning'
            })
        );
    }
}
