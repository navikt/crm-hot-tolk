import { LightningElement, api } from 'lwc';

export default class Input extends LightningElement {
    @api label;
    @api name;
    @api value;
    @api type;
    @api errorText;
    @api desktopStyle;
    @api mobileStyle;
    @api choices;
    @api masterLabel;
    @api checkboxes;
    @api header;

    @api getValue() {
        return this.value;
    }

    @api setValue(value) {
        this.value = value;
    }

    @api sendErrorMessage() {}
}
