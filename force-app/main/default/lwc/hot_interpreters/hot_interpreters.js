import { LightningElement, api, wire, track } from 'lwc';
import getInterpreters from '@salesforce/apex/HOT_InterpreterOnWorkOrderService.getInterpreters';

export default class Hot_interpreters extends LightningElement {
    @api objectName;
    @api mergeField;
    @api recordId;
    @api commaSeperatedList = false;
    @track interpreters;

    @wire(getInterpreters, { recordId: '$recordId', mergeField: '$mergeField', objectName: '$objectName' })
    wirdedGetInterpreters(result) {
        if (result.data) {
            if (this.commaSeperatedList) {
                let interpreters = '';
                for (let interpreter of result.data) {
                    interpreters += interpreter + ', ';
                }
                interpreters = interpreters.slice(0, -2);
                this.interpreters = interpreters;
            } else {
                this.interpreters = result.data;
            }
        }
    }
}
