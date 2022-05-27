import { LightningElement, api } from 'lwc';
import logos from '@salesforce/resourceUrl/crmHenvendelse_personlogo';

export default class MessagingCommunityMessageOutbound extends LightningElement {
    @api message;
    navlogo = logos;
}
