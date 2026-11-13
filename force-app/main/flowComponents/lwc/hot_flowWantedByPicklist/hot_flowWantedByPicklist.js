import { LightningElement, api } from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';

export default class Hot_flowWantedByPicklist extends LightningElement {
    @api label;
    @api value;
    @api option1;
    @api option2;
    @api option3;
    @api required = false;

    get options() {
        return [this.option1, this.option2, this.option3]
            .filter((option) => option != null && String(option).trim() !== '')
            .map((option) => ({ label: option, value: option, selected: option === this.value }));
    }

    handleChange(event) {
        this.value = event.target.value;
        this.dispatchEvent(new FlowAttributeChangeEvent('value', this.value));
    }
}
