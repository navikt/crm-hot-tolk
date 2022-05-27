import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import NAME_FIELD from '@salesforce/schema/Conversation_Note__c.Name';
import TEXT_FIELD from '@salesforce/schema/Conversation_Note__c.CRM_Conversation_Note__c';
import IS_REDACTED_FIELD from '@salesforce/schema/Conversation_Note__c.CRM_Is_Redacted__c';

export default class CrmConversationNoteRedactText extends LightningElement {
    @api recordId;
    redactedText;
    trueValue;
    _isRedacting = false;
    showSpinner = false;

    @wire(getRecord, {
        recordId: '$recordId',
        fields: [NAME_FIELD, TEXT_FIELD, IS_REDACTED_FIELD]
    })
    wiredConversationNote;

    get text() {
        return getFieldValue(this.wiredConversationNote.data, TEXT_FIELD);
    }

    set isRedacting(value) {
        if (false === value) {
            this.revertRedacting();
        }
        this._isRedacting = value;
    }

    get isRedacting() {
        return this._isRedacting;
    }

    get canSaveDisabled() {
        return this.template.querySelector('c-hot_redact-text')
            ? !this.template.querySelector('c-hot_redact-text').hasChanges
            : false;
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

    revertRedacting() {
        this.template.querySelector('c-hot_redact-text').reset();
    }

    toggleRedacting() {
        this.isRedacting = !this.isRedacting;
    }

    handleRedactEvent(event) {
        event.preventDefault();
        this.redactedText = event.detail;
    }
}
