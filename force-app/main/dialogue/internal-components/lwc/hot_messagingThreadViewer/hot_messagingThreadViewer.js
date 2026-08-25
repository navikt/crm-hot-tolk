import { LightningElement, api, wire } from 'lwc';
import getmessages from '@salesforce/apex/HOT_MessageHelper.getMessagesFromThread';
import markAsReadByNav from '@salesforce/apex/HOT_MessageHelper.markAsReadByNav';
import markMessagesAsTjenesteleverandor from '@salesforce/apex/HOT_MessageHelper.markMessagesAsTjenesteleverandor';
import { subscribe, unsubscribe } from 'lightning/empApi';
import setLastMessageFrom from '@salesforce/apex/HOT_MessageHelper.setLastMessageFrom';
import getUserNameRole from '@salesforce/apex/HOT_MessageHelper.getUserNameRole';
import markThreadAsReadEmployee from '@salesforce/apex/HOT_MessageHelper.markThreadAsReadEmployee';
import userId from '@salesforce/user/Id';
import { updateRecord } from 'lightning/uiRecordApi';
import getThreadByIdWithReplyPolicy from '@salesforce/apex/HOT_MessageHelper.getThreadByIdWithReplyPolicy';
import ACTIVE_FIELD from '@salesforce/schema/Thread__c.CRM_isActive__c';
import THREAD_ID_FIELD from '@salesforce/schema/Thread__c.Id';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

export default class hot_messagingThreadViewer extends LightningElement {
    createdbyid;
    usertype;
    otheruser;
    _mySendForSplitting;
    @api thread;
    threadheader;
    threadid;
    messages = [];
    showspinner = false;
    hideModal = true;
    @api showClose;
    @api englishTextTemplate;
    @api setInputInFocusOnRender;
    _isTjenesteLeverandorFormidlerView = false;
    langBtnLock = false;
    langBtnAriaToggle = false;
    newMessage = false;
    hasAccess = false;
    showAccessError = false;
    canReply = true;
    canceledSABannerText =
        'Oppdraget er avlyst. Du kan se samtalen i 48 timer etter avlysning. Du kan ikke sende nye meldinger.';

    wiredThread = {};

    @api textTemplate; //Support for conditional text template as input
    //Constructor, called onload
    @api focusOnInput() {
        let qtext = this.template.querySelector('c-hot_messaging-quick-text');
        if (qtext) {
            qtext.focusOnInput();
        }
    }

    _showMessageInput = true;

    @api
    get showMessageInput() {
        return this._showMessageInput;
    }

    set showMessageInput(value) {
        this._showMessageInput = !(value === false || value === 'false');
    }

    @api
    get isTjenesteLeverandorFormidlerView() {
        return this._isTjenesteLeverandorFormidlerView;
    }

    set isTjenesteLeverandorFormidlerView(value) {
        this._isTjenesteLeverandorFormidlerView = value;
        if (value && this.messages.length > 0) {
            this.markMessagesAsTjenesteleverandor(this.messages);
        }
    }

    connectedCallback() {
        if (this.thread) {
            this.threadid = this.thread.Id;
            getThreadByIdWithReplyPolicy({ threadId: this.threadid })
                .then((result) => {
                    this.hasAccess = true;
                    this.showAccessError = false;
                    this.wiredThread = result.thread;
                    this.canReply = result.replyPolicy?.canReply !== false;
                    this.handleSubscribe();
                    this.scrolltobottom();
                    this.markThreadAsRead();
                    console.log('isTjenesteleverandorFormidlerView result: ', this.isTjenesteLeverandorFormidlerView);
                })
                .catch((error) => {
                    if (error.body.message === 'No access') {
                        this.showAccessError = true;
                        this.hasAccess = false;
                    } else {
                        console.log('Error in getThreadById:', error);
                    }
                });
        }
    }
    disconnectedCallback() {
        this.handleUnsubscribe();
    }
    renderedCallback() {
        this.refreshMessages();
        if (this.newMessage) {
            this.markThreadAsRead();
            this.newMessage = false;
        }
        this.scrolltobottom();
        if (this.setInputInFocusOnRender) {
            this.focusOnInput();
        }
    }

    //Handles subscription to streaming API for listening to changes to auth status
    handleSubscribe() {
        let _this = this;
        // Callback invoked whenever a new message event is received
        const messageCallback = function (response) {
            const messageThreadId = response.data.sobject.CRM_Thread__c;
            if (_this.threadid == messageThreadId) {
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

    markMessagesAsTjenesteleverandor(messages) {
        if (!this.isTjenesteLeverandorFormidlerView) {
            return;
        }
        const messageIds = messages
            .filter((message) => !message.HOT_IsTjenesteleverandorMessage__c)
            .map((message) => message.Id);

        if (messageIds.length === 0) {
            return;
        }

        markMessagesAsTjenesteleverandor({ messageIds })
            .then(() => this.refreshMessages())
            .then(() => {
                console.log(
                    'Messages marked as tjenesteleverandor successfully' +
                        (messageIds.length > 0 ? ` for message IDs: ${messageIds.join(', ')}` : '')
                );
                const updatedMessages = this.messages.filter((message) => messageIds.includes(message.Id));
                const newestMessage = updatedMessages[updatedMessages.length - 1];
                console.log(
                    'Newest message marked, HOT_IsTjenesteleverandorMessage__c:',
                    newestMessage.Id,
                    newestMessage.HOT_IsTjenesteleverandorMessage__c
                );
            })
            .catch((error) => {
                console.error('Unable to mark messages as tjenesteleverandor:', error);
            });
    }

    @wire(getmessages, { threadId: '$threadid' }) //Calls apex and extracts messages related to this record
    wiremessages(result) {
        this._mySendForSplitting = result;
        if (result.error) {
            this.error = result.error;
        } else if (result.data) {
            this.messages = result.data;
            this.showspinner = false;
            this.markMessagesAsTjenesteleverandor(result.data);
        }
    }
    //If empty, stop submitting.
    handlesubmit(event) {
        this.lockLangBtn();
        event.preventDefault();
        if (!this.canReply) {
            this.showClosedToast();
            return;
        }
        if (!this.quickTextCmp.isOpen()) {
            this.showspinner = true;
            const textInput = event.detail.fields;
            // If messagefield is empty, stop the submit
            textInput.CRM_Thread__c = this.thread.Id;
            textInput.CRM_From_User__c = userId;
            textInput.CRM_Message_Text__c = this.text;
            //her
            getUserNameRole().then((result) => {
                textInput.HOT_User_Role__c = result;
                if (textInput.CRM_Message_Text__c == null || textInput.CRM_Message_Text__c === '') {
                    const event1 = new ShowToastEvent({
                        title: 'Message Body missing',
                        message: 'Make sure that you fill in the message text',
                        variant: 'error'
                    });
                    this.dispatchEvent(event1);
                    this.showspinner = false;
                } else {
                    this.template.querySelector('lightning-record-edit-form').submit(textInput);
                    setLastMessageFrom({ threadId: this.thread.Id, fromContactId: 'ansatt/formidler' });
                    this.newMessage = true;
                }
            });
        }
    }

    //Enriching the toolbar event with reference to the thread id
    //A custom toolbaraction event can be passed from the component in the toolbar slot that the thread viewer enrich with the thread id
    handleToolbarAction(event) {
        let threadId = this.threadid;
        let eventDetails = event.detail;
        eventDetails.threadId = threadId;
        event.threadId = threadId;
    }

    closeThread() {
        this.closeModal();
        const fields = {};
        fields[THREAD_ID_FIELD.fieldApiName] = this.threadid;
        fields[ACTIVE_FIELD.fieldApiName] = false;

        const threadInput = { fields };
        this.showspinner = true;
        updateRecord(threadInput)
            .then(() => {
                const event1 = new ShowToastEvent({
                    title: 'Avsluttet',
                    message: 'Samtalen ble avsluttet',
                    variant: 'success'
                });
                this.dispatchEvent(event1);
            })

            .catch((error) => {
                console.log(JSON.stringify(error, null, 2));
                const event1 = new ShowToastEvent({
                    title: 'Det oppstod en feil',
                    message: 'Samtalen kunne ikke bli avsluttet',
                    variant: 'error'
                });
                this.dispatchEvent(event1);
            })
            .finally(() => {
                this.refreshMessages();
                this.showspinner = false;
            });
    }

    handlesuccess(event) {
        this.recordId = event.detail;

        this.quickTextCmp.clear();
        const inputFields = this.template.querySelectorAll('.msgText');

        if (inputFields) {
            inputFields.forEach((field) => {
                field.reset();
            });
        }
        //this.showspinner = false;
        this.showspinner = false;
        this.refreshMessages();
    }

    scrolltobottom() {
        var element = this.template.querySelector('.slds-box');
        if (element) {
            element.scrollTop = element.scrollHeight;
        }
    }
    refreshMessages() {
        return refreshApex(this._mySendForSplitting);
    }

    async markThreadAsRead() {
        try {
            await Promise.all([
                markAsReadByNav({ threadId: this.threadid }),
                markThreadAsReadEmployee({ threadId: this.threadid })
            ]);
            this.dispatchEvent(
                new CustomEvent('threadread', {
                    detail: { threadId: this.threadid }
                })
            );
        } catch (error) {
            console.log('Unable to mark thread as read:', error);
        }
    }

    showQuickText(event) {
        this.quickTextCmp.showModal(event);
    }

    handleLangClick() {
        const englishEvent = new CustomEvent('englishevent', {
            detail: !this.englishTextTemplate
        });
        this.langBtnAriaToggle = !this.langBtnAriaToggle;
        this.dispatchEvent(englishEvent);
    }

    lockLangBtn() {
        this.langBtnLock = true;
    }

    //##################################//
    //#########    GETTERS    ##########//
    //##################################//

    get registereddate() {
        return this.wiredThread?.CRM_Date_Time_Registered__c;
    }

    get closedThread() {
        return !this.wiredThread?.CRM_isActive__c || !this.canReply;
    }

    get showReplyInput() {
        return !this.closedThread;
    }

    get replyClosedText() {
        return 'Denne samtalen er stengt for videre dialog.';
    }
    get quickTextCmp() {
        return this.template.querySelector('c-hot_messaging-quick-text');
    }

    get text() {
        return this.quickTextCmp ? this.quickTextCmp.conversationNote : '';
    }

    showClosedToast() {
        const event = new ShowToastEvent({
            title: 'Samtalen er stengt',
            message: this.replyClosedText,
            variant: 'error'
        });
        this.dispatchEvent(event);
    }

    get modalClass() {
        return 'slds-modal slds-show uiPanel north' + (this.hideModal === true ? ' geir' : ' slds-fade-in-open');
    }

    get backdropClass() {
        return this.hideModal === true ? 'slds-hide' : 'backdrop';
    }

    get langBtnVariant() {
        return this.englishTextTemplate === false ? 'neutral' : 'brand';
    }

    get langAria() {
        return this.langBtnAriaToggle === false ? 'Språk knapp, Norsk' : 'Språk knapp, Engelsk';
    }

    get hasEnglishTemplate() {
        return this.englishTextTemplate !== undefined;
    }

    //##################################//
    //########    MODAL    #############//
    //##################################//

    openModal() {
        this.hideModal = false;
    }

    closeModal() {
        this.hideModal = true;
        const btn = this.template.querySelector('.endDialogBtn');
        btn.focus();
    }

    trapFocusStart() {
        const firstElement = this.template.querySelector('.closeButton');
        firstElement.focus();
    }

    trapFocusEnd() {
        const lastElement = this.template.querySelector('.cancelButton');
        lastElement.focus();
    }
}
