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
    @api labelSize;
    @api value;
    @api selectedValue;
    @api showNavButtons = false;

    @api option1;
    @api option2;
    @api option3;

    @api required = false;
    errorMessage = '';

    get options() {
        return [
            { label: this.option1, name: this.option1, value: this.option1 },
            { label: this.option2, name: this.option2, value: this.option2 },
            { label: this.option3, name: this.option3, value: this.option3 }
        ].filter((option) => option.value != null && String(option.value).trim() !== '');
    }

    handleChange(event) {
        const detail = event.detail;
        const selectedValue = detail?.value ?? detail?.name ?? detail?.selectedValue ?? detail;
        this.value = typeof selectedValue === 'string' ? selectedValue : '';
        this.selectedValue = this.value;
        this.errorMessage = '';
        this.dispatchEvent(new FlowAttributeChangeEvent('selectedValue', this.selectedValue));
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
        this.selectedValue = this.value;
        this.dispatchEvent(new FlowAttributeChangeEvent('selectedValue', this.selectedValue));
        this.dispatchEvent(new FlowAttributeChangeEvent('value', this.value));
        this.dispatchEvent(new FlowNavigationNextEvent());
    }
}
