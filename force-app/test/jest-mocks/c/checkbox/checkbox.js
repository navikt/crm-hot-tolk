import { LightningElement, api } from 'lwc';

export default class Checkbox extends LightningElement {
    @api label;
    @api defaultVal;
    @api desktopStyle;
    @api mobileStyle;

    @api
    setCheckboxValue(value) {
        this.defaultVal = value;
    }
}
