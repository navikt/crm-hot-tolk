import { LightningElement, api, wire, track } from 'lwc';
import getUserNameRole from '@salesforce/apex/HOT_MessageHelper.getUserNameRole';
import userId from '@salesforce/user/Id';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class hot_messagingThreadViewerMock extends LightningElement {
    showspinner = false;
    hideModal = true;
    @api setInputInFocusOnRender;
    @api focusOnInput() {
        let qtext = this.template.querySelector('c-hot_messaging-quick-text');
        if (qtext) {
            qtext.focusOnInput();
        }
    }
    renderedCallback() {
        this.focusOnInput();
    }

    //If empty, stop submitting.
    handlesubmit(event) {
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
                    this.dispatchEvent(new CustomEvent('createthreadwithmessage', { detail: textInput }));
                    this.showspinner = false;
                }
            });
        }
    }

    showQuickText(event) {
        this.quickTextCmp.showModal(event);
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
    get message() {
        return {
            CRM_Message_Text__c: 'Samtale er ikke påbegynt enda. Skriv en melding for å starte samtalen.',
            CRM_Event_Type__c: 'OTHER',
            CRM_Type__c: 'Event'
        }; //Default message to show in thread viewer mock before conversation starts
    }
}
