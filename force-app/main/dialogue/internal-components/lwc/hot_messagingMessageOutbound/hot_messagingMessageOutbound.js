import { LightningElement, api } from 'lwc';

export default class MessagingMessageOutbound extends LightningElement {
    @api message;
    @api userid;

    get isOwner() {
        if (this.userid == this.message.CRM_From_User__c) {
            return true;
        }
        return false;
    }

    get isInfo() {
        return this.message.CRM_Type__c === 'Info' ? true : false;
    }
}
