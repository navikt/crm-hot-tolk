import { LightningElement, api } from 'lwc';

export default class Hot_flowPicklist extends LightningElement {
    @api label;
    @api required = false;
    @api value;

    @api picklistValueMap;
}
