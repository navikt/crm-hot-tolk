import { LightningElement, api } from 'lwc';
import IKONER from '@salesforce/resourceUrl/ikoner';

export default class Icon extends LightningElement {
    @api icon;
    @api ariaLabel;
    get iconToShow() {
        return IKONER + '/' + this.icon + '.svg#' + this.icon;
    }
    get defaultStyle() {
        return 'width: 24px; height: 24px';
    }
}
