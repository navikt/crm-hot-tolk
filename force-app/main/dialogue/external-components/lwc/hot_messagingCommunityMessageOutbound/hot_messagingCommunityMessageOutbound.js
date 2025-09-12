import { LightningElement, api } from 'lwc';
import logos from '@salesforce/resourceUrl/hot_Henvendelse_personlogo';

export default class MessagingCommunityMessageOutbound extends LightningElement {
    @api message;
    navlogo = logos;

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
