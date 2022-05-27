import { LightningElement, api } from 'lwc';
import logos from '@salesforce/resourceUrl/stoLogos';

export default class CommunityMessageInbound extends LightningElement {
    @api message;
    navlogo = logos + '/navLogoRed.svg';
}
