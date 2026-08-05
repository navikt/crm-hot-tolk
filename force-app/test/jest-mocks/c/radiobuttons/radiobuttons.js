import { LightningElement, api } from 'lwc';

export default class Radiobuttons extends LightningElement {
    @api radiobuttons = [];
    @api groupName;
    @api errorText;
}
