import { LightningElement, api } from 'lwc';
import {
    FlowAttributeChangeEvent,
    FlowNavigationBackEvent,
    FlowNavigationNextEvent,
    FlowNavigationPauseEvent,
    FlowNavigationFinishEvent
} from 'lightning/flowSupport';

export default class Hot_flowPicklist extends LightningElement {
    @api label;
    @api value;

    @api option1;
    @api option2;
    @api option3;

    @api required = false;
    errorMessage = '';

    get options() {
        return [
            { label: this.option1, value: this.option1 },
            { label: this.option2, value: this.option2 },
            { label: this.option3, value: this.option3 }
        ];
    }

    handleChange(event) {
        this.value = event.detail.value;
        this.errorMessage = '';
        this.dispatchEvent(new FlowAttributeChangeEvent('value', this.value));
    }

    handleBack() {
        this.dispatchEvent(new FlowNavigationBackEvent());
    }

    handleNext() {
        // If required, make sure a value is selected
        if (this.required && (!this.value || this.value === '')) {
            this.errorMessage = 'Vennligst velg et alternativ for å fortsette.';
            return;
        }
        this.dispatchEvent(new FlowNavigationNextEvent());
    }
}
