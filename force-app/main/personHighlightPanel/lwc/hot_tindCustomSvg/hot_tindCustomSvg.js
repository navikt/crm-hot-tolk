import { LightningElement, api } from 'lwc';

export default class hotCustomSvg extends LightningElement {
    @api size;
    @api altText;
    @api src;
    @api classes;
    @api viewBox;

    get iconClasses() {
        let styleClasses = 'slds-icon slds-icon-text-default';
        styleClasses += this.classes ? ' ' + this.classes : '';
        switch (this.size) {
            case 'xx-small':
                return styleClasses + ' slds-icon_xx-small';
            case 'x-small':
                return styleClasses + ' slds-icon_x-small';
            case 'small':
                return styleClasses + ' slds-icon_small';
            case 'large':
                return styleClasses + ' slds-icon_large';
            default:
                return styleClasses;
        }
    }
}
