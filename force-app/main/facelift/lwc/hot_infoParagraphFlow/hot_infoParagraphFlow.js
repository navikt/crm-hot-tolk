import { LightningElement, api } from 'lwc';
import { FlowAttributeChangeEvent, FlowNavigationFinishEvent } from 'lightning/flowSupport';

export default class Hot_infoParagraphFlow extends LightningElement {
    @api label;
    @api text;
    @api fontSize = 'medium';
    @api headerSize = 'header-medium';

    get headerClass() {
        switch (this.headerSize) {
            case 'header-small':
                return 'header-small';
            case 'header-large':
                return 'header-large';
            default:
                return 'header-medium';
        }
    }

    get textClass() {
        switch (this.fontSize) {
            case 'small':
                return 'text-small';
            case 'large':
                return 'text-large';
            default:
                return 'text-medium';
        }
    }
}
