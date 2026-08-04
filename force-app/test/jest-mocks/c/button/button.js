import { LightningElement, api } from 'lwc';

export default class Button extends LightningElement {
    @api buttonLabel;
    @api buttonStyling;
    @api ariaLabel;
    @api disabled = false;

    handleClick() {
        if (!this.disabled) {
            this.dispatchEvent(new CustomEvent('buttonclick'));
        }
    }
}
