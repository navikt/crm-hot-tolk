import { LightningElement, api } from 'lwc';
import logo from '@salesforce/resourceUrl/hot_tindLogo';

export default class CommunityMessageInbound extends LightningElement {
    @api message;
    tindLogo = logo;
}
