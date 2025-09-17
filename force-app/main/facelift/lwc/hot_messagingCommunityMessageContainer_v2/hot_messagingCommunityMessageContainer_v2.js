import { LightningElement, api } from 'lwc';
import uId from '@salesforce/user/Id';

export default class Hot_messagingCommunityMessageContainer_v2 extends LightningElement {
    @api message;
    @api userContactId;

    userId = uId;

    get isoutbound() {
        return (
            (this.userId && this.userId == this.message.CRM_From_User__c) ||
            (this.userContactId && this.userContactId == this.message.CRM_From_Contact__c)
        );
    }

    get isevent() {
        return this.message.CRM_Type__c == 'Event';
    }
}
