import { LightningElement, api } from 'lwc';

export default class Button extends LightningElement {
    @api buttonLabel;
    @api buttonStyling;
    @api ariaLabel;
    @api disabled = false;
    @api desktopStyle;
    @api mobileStyle;
    @api hidden = false;
    @api title;
    @api type;

    handleClick() {
        if (!this.disabled) {
            this.dispatchEvent(new CustomEvent('buttonclick'));
        }
    }
}
