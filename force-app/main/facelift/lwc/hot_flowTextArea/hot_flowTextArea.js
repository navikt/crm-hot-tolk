import { LightningElement, api } from 'lwc';
import {
    FlowAttributeChangeEvent,
    FlowNavigationBackEvent,
    FlowNavigationNextEvent,
    FlowNavigationPauseEvent,
    FlowNavigationFinishEvent
} from 'lightning/flowSupport';

export default class Hot_flowTextArea extends LightningElement {
    @api label;
    @api inputText = '';
    @api required = false;
    @api errorText = '';

    // Check if input is valid; show error if required and empty
    validate() {
        if (this.required && (!this.inputText || this.inputText.trim() === '')) {
            this.errorText = 'Vennligst fyll ut tekstfeltet for å gå videre.';
            return false;
        }
        this.errorText = '';
        return true;
    }

    handleUserInputTextarea(event) {
        this.inputText = event.detail;

        this.dispatchEvent(new FlowAttributeChangeEvent('inputText', this.inputText));

        if (this.errorText && this.inputText.trim() !== '') {
            this.errorText = '';
        }
    }

    handleBack() {
        this.dispatchEvent(new FlowNavigationBackEvent());
    }

    handleNext() {
        const isValid = this.validate();
        if (!isValid) {
            return;
        }

        this.dispatchEvent(new FlowNavigationNextEvent());
    }
}
