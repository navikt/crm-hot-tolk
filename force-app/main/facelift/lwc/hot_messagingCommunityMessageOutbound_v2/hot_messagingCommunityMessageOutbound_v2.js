import { LightningElement, api } from 'lwc';

export default class Hot_messagingCommunityMessageOutbound_v2 extends LightningElement {
    @api message;

    // Uppercase on the first letter of each word
    get formattedFirstName() {
        if (!this.message?.CRM_From_First_Name__c) {
            return '';
        }

        return this.message.CRM_From_First_Name__c.trim()
            .split(' ')
            .map((word) => word.charAt(0).toUpperCase() + word.slice(1).toLowerCase())
            .join(' ');
    }
}
