import { LightningElement, api, wire, track } from 'lwc';
import getInterpreters from '@salesforce/apex/HOT_InterpreterOnWorkOrderService.getInterpreters';
import getInterpreters2 from '@salesforce/apex/HOT_InterpreterOnWorkOrderService.getInterpreters2';

export default class Hot_interpreters extends LightningElement {
    @api objectName = 'WorkOrder';
    @api mergeField = 'Id';
    @api recordId;
    @api workOrderId;
    @api hideHtml;
    @track interpreters = [];

    //@wire(getInterpreters, { recordId: '$recordId', mergeField: '$mergeField', objectName: '$objectName' })
    //wirdedGetInterpreters(result) {
    //    console.log(JSON.stringify(result));
    //    if (result.data) {
    //        this.interpreters = result.data;
    //    }
    //}
    connectedCallback() {
        console.log(this.mergeField);
        console.log(this.recordId);
        console.log(this.interpreters);
    }

    @wire(getInterpreters2, { workOrderId: '$workOrderId' })
    wirdedGetInterpreters2(result) {
        console.log(JSON.stringify(result));
        if (result.data) {
            this.interpreters = result.data;
        }
    }
}
