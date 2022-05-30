import { LightningElement, api } from 'lwc';
import logos from '@salesforce/resourceUrl/hot_Henvendelse_personlogo';

export default class MessagingCommunityMessageOutbound extends LightningElement {
    @api message;
    navlogo = logos;
}
