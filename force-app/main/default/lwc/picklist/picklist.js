import { LightningElement, api } from 'lwc';

export default class Picklist extends LightningElement {
    @api masterLabel;
    @api choices = [];
    @api disabled;

    @api choiceValue;
    handleChoiceMade(event) {
        this.choiceValue = event.target.value;
        const eventToSend = new CustomEvent('picklistvaluechange', { detail: this.choiceValue });
        this.dispatchEvent(eventToSend);
    }

    renderedCallback() {
        this.template.querySelector('.select-element').disabled = true;
    }
}
