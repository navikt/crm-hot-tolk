import { LightningElement, api } from 'lwc';

export default class MessageEvent extends LightningElement {
    @api message;
    get endOfChatMessage() {
        return 'avsluttet samtalen - ';
    }
    get transferMessage() {
        if (this.message.CRM_Event_Type__c === 'UNIT_TRANSFER' || this.message.CRM_Event_Type__c === 'QUEUE_TRANSFER')
            return 'Samtalen din er overført til avdelingen ' + this.message.CRM_Message_Text__c + ' - ';
        return this.message.CRM_Message_Text__c;
    }
    get journalMessage() {
        if (this.message.CRM_Event_Type__c === 'JOURNAL') return 'Tråden ble journalført. ';
        return this.message.CRM_Message_Text__c;
    }
    get isEndChatEvent() {
        if (
            this.message.CRM_Event_Type__c === 'END_OF_CHAT' ||
            String(this.message.CRM_Message_Text__c).includes('avslutt') /*deprecated*/
        )
            return true;
        return false;
    }
    get isTransferEvent() {
        if (
            this.message.CRM_Event_Type__c === 'UNIT_TRANSFER' ||
            this.message.CRM_Event_Type__c === 'QUEUE_TRANSFER' ||
            String(this.message.CRM_Message_Text__c).includes('overført') /*deprecated*/
        )
            return true;
        return false;
    }
    get isJournalEvent() {
        if (
            this.message.CRM_Event_Type__c === 'JOURNAL' ||
            String(this.message.CRM_Message_Text__c).includes('journalført') /*deprecated*/
        )
            return true;
        return false;
    }
    get isOtherEvent() {
        if (this.isEndChatEvent || this.isTransferEvent || this.isJournalEvent) return false;
        return true;
    }
}
