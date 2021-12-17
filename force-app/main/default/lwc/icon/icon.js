import { LightningElement, api } from 'lwc';
import IKONER from '@salesforce/resourceUrl/ikoner';

export default class Icon extends LightningElement {
    @api icon;
    @api ariaLabel;
    @api fill;
    @api svgStyle;

    get iconToShow() {
        let fill = this.fill !== undefined ? this.fill : '';
        return IKONER + '/' + this.icon + '/' + this.icon + fill + '.svg#' + this.icon + fill;
    }
    get defaultStyle() {
        return this.svgStyle === undefined ? 'width: 24px; height: 24px' : this.svgStyle;
    }
}
