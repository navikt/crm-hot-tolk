import { LightningElement, api } from 'lwc';

export default class Picklist extends LightningElement {
    @api masterLabel;
    @api choices = [];

    @api choiceValue;
    handleChoiceMade(event) {
        console.log('Event: ' + JSON.stringify(event));
        console.log('Event detail: ' + JSON.stringify(event.detail));
        console.log('Event.detail.value: ' + JSON.stringify(event.detail.value));
        /*this.choiceValue = event.detail;
        const eventToSend = new CustomEvent('picklistvaluechange', { detail: this.choiceValue });
        console.log('event: ' + eventToSend);
        this.dispatchEvent(eventToSend);*/
    }
}
