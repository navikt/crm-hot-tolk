import { LightningElement, api, wire, track } from 'lwc';
import getUserNameRole from '@salesforce/apex/HOT_MessageHelper.getUserNameRole';
import userId from '@salesforce/user/Id';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class hot_messagingThreadViewerMock extends LightningElement {
    showspinner = false;
    hideModal = true;
    @api englishTextTemplate;
    @api setInputInFocusOnRender;
    @track langBtnLock = false;
    langBtnAriaToggle = false;

    @api textTemplate; //Support for conditional text template as input
    //Constructor, called onload
    @api focusOnInput() {
        let qtext = this.template.querySelector('c-hot_messaging-quick-text');
        if (qtext) {
            qtext.focusOnInput();
        }
    }
    connectedCallback() {}
    disconnectedCallback() {}
    renderedCallback() {
        this.focusOnInput();
    }

    //Handles subscription to streaming API for listening to changes to auth status
    handleSubscribe() {}

    handleUnsubscribe() {}

    //If empty, stop submitting.
    handlesubmit(event) {
        this.lockLangBtn();
        event.preventDefault();
        if (!this.quickTextCmp.isOpen()) {
            this.showspinner = true;
            const textInput = {};
            // If messagefield is empty, stop the submit
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
                    //this.template.querySelector('lightning-record-edit-form').submit(textInput);
                    console.log('Submitting message: ', JSON.stringify(textInput));
                    this.dispatchEvent(new CustomEvent('createthreadwithmessage', { detail: textInput }));
                    this.showspinner = false;
                    //setLastMessageFrom({ threadId: this.thread.Id, fromContactId: 'ansatt/formidler' });
                }
            });
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

    get quickTextCmp() {
        return this.template.querySelector('c-hot_messaging-quick-text');
    }

    get text() {
        return this.quickTextCmp ? this.quickTextCmp.conversationNote : '';
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
    get message() {
        return {
            CRM_Message_Text__c: 'Samtale er ikke påbegynt enda. Skriv en melding for å starte samtalen.',
            CRM_Event_Type__c: 'OTHER',
            CRM_Type__c: 'Event'
        }; //Default message to show in thread viewer mock before conversation starts
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
