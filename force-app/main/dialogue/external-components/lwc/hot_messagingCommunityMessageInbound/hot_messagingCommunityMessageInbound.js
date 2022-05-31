import { LightningElement, api } from 'lwc';
import logos from '@salesforce/resourceUrl/hot_tindLogo';

export default class CommunityMessageInbound extends LightningElement {
    @api message;
    tindlogo = logos + '/tindLogo.png';
}
