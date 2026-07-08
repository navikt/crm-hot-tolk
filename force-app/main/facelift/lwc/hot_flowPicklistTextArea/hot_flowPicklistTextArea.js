import { LightningElement, api } from 'lwc';
import { FlowAttributeChangeEvent, FlowNavigationBackEvent, FlowNavigationNextEvent } from 'lightning/flowSupport';

export default class Hot_flowPicklistTextArea extends LightningElement {
    @api label;
    @api value;

    @api option1;
    @api option2;
    @api option3;

    @api textareaLabel;
    @api inputText = '';
    @api requiredPicklist = false;
    @api requiredTextarea = false;
    @api option1RequiresTextarea = false;
    @api option2RequiresTextarea = false;
    @api option3RequiresTextarea = false;

    errorMessagePicklist = '';
    errorMessageTextarea = '';

    get options() {
        return [
            { label: this.option1, value: this.option1 },
            { label: this.option2, value: this.option2 },
            { label: this.option3, value: this.option3 }
        ].filter((option) => option.label);
    }

    get isPicklistRequired() {
        return this.requiredPicklist;
    }

    get selectedOptionRequiresTextarea() {
        if (this.value === this.option1) {
            return this.option1RequiresTextarea;
        }
        if (this.value === this.option2) {
            return this.option2RequiresTextarea;
        }
        if (this.value === this.option3) {
            return this.option3RequiresTextarea;
        }
        return false;
    }

    get isTextareaRequired() {
        return this.requiredTextarea || this.selectedOptionRequiresTextarea;
    }

    handlePicklistChange(event) {
        this.value = event.detail.value;
        this.errorMessagePicklist = '';
        this.dispatchEvent(new FlowAttributeChangeEvent('value', this.value));
    }

    handleTextareaChange(event) {
        this.inputText = event.detail;
        this.errorMessageTextarea = '';
        this.dispatchEvent(new FlowAttributeChangeEvent('inputText', this.inputText));
    }

    handleBack() {
        this.dispatchEvent(new FlowNavigationBackEvent());
    }

    handleNext() {
        let isValid = true;

        if (this.isPicklistRequired && (!this.value || this.value === '')) {
            this.errorMessagePicklist = 'Vennligst velg et alternativ for å fortsette.';
            isValid = false;
        }

        if (this.isTextareaRequired && (!this.inputText || this.inputText.trim() === '')) {
            this.errorMessageTextarea = 'Vennligst fyll ut tekstfeltet for å gå videre.';
            isValid = false;
        }

        if (!isValid) {
            return;
        }

        this.dispatchEvent(new FlowNavigationNextEvent());
    }
}
