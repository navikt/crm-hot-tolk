import { LightningElement, api, track } from 'lwc';

export default class CrmMessagingRedactMessage extends LightningElement {
    _message;
    messageId;
    messageText;
    redactedText;
    _isRedacting = false;
    trueValue = true;
    showSpinner = false;
    @track redactAll = false;

    @api get message() {
        return this._message;
    }

    get isEvent() {
        return this.message.CRM_Type__c === 'Event' ? true : false;
    }

    get isInfo() {
        return this.message.CRM_Type__c === 'Info' ? true : false;
    }

    set isRedacting(value) {
        if (false === value) {
            this.redactTextComponent.reset(); //this.revertRedacting();
        }
        this._isRedacting = value;
    }

    get isRedacting() {
        return this._isRedacting;
    }

    get isInbound() {
        return this.message.CRM_External_Message__c ? true : false;
    }

    set message(value) {
        this._message = value;
        this.messageText = this.message.CRM_Message_Text__c;
        this.redactedText = this.message.CRM_Message_Text__c;
        this.messageId = this.message.Id;
    }

    handleSuccess() {
        this.showSpinner = false;
        this.isRedacting = false;
    }

    handleError() {
        this.showSpinner = false;
        this.isRedacting = false;
    }

    handleSubmit() {
        this.showSpinner = true;
    }

    get liClasses() {
        const cssClass = this.message.CRM_External_Message__c
            ? 'slds-chat-listitem_inbound'
            : 'slds-chat-listitem_outbound';
        return `slds-chat-listitem ${cssClass}`;
    }

    get divClasses() {
        const cssClass = this.message.CRM_External_Message__c
            ? 'slds-chat-message__text_inbound'
            : 'slds-chat-message__text_outbound';
        return `slds-chat-message__text ${cssClass}`;
    }

    get redactTextComponent() {
        return this.template.querySelector('c-hot_redact-text');
    }

    get canSaveDisabled() {
        return this.redactTextComponent ? !this.redactTextComponent.hasChanges : false;
    }

    toggleRedacting() {
        this.isRedacting = !this.isRedacting;
    }

    handleRedactEvent(event) {
        event.preventDefault();
        this.redactedText = event.detail;
    }

    RedactAllMessageText() {
        this.redactedText = '***';
        this.redactTextComponent.addRedactedValue(this.redactedText);

        this.redactAll = true;
        this.dispatchEvent(new CustomEvent('redactall', { detail: this.redactAll }));
    }
}
