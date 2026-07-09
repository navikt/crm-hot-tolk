import { LightningElement, api } from 'lwc';
import { FlowAttributeChangeEvent, FlowNavigationBackEvent, FlowNavigationNextEvent } from 'lightning/flowSupport';

const PICKLIST_ERROR_MESSAGE = 'Vennligst velg et alternativ for å fortsette.';
const TEXTAREA_ERROR_MESSAGE = 'Vennligst fyll ut tekstfeltet for å gå videre.';

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

    textAreaValidationError = false;

    get options() {
        return [
            { label: this.option1, name: this.option1, value: this.option1, selected: this.value === this.option1 },
            { label: this.option2, name: this.option2, value: this.option2, selected: this.value === this.option2 },
            { label: this.option3, name: this.option3, value: this.option3, selected: this.value === this.option3 }
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
    get isLabel() {
        return this.label && this.label.trim() !== '';
    }
    get isTextareaLabel() {
        return this.textareaLabel && this.textareaLabel.trim() !== '';
    }
    get labelValue() {
        return this.isPicklistRequired ? `* ${this.label}` : this.label;
    }
    get textareaLabelValue() {
        return this.isTextareaRequired ? `* ${this.textareaLabel}` : this.textareaLabel;
    }
    handlePicklistChange(event) {
        this.value = event.detail.value;
        this.resetPicklistError();
        if (this.textAreaValidationError) {
            if (this.isTextareaValid()) {
                this.resetTextareaError();
            } else {
                this.setTextareaError(TEXTAREA_ERROR_MESSAGE);
            }
        }
        this.dispatchEvent(new FlowAttributeChangeEvent('value', this.value));
    }

    handleTextareaChange(event) {
        this.inputText = event.detail;
        if (this.isTextareaValid()) {
            this.resetTextareaError();
        } else {
            this.setTextareaError(TEXTAREA_ERROR_MESSAGE);
        }
        this.dispatchEvent(new FlowAttributeChangeEvent('inputText', this.inputText));
    }

    handleBack() {
        this.dispatchEvent(new FlowNavigationBackEvent());
    }

    handleNext() {
        if (this.isPicklistValid() && this.isTextareaValid()) {
            this.dispatchEvent(new FlowNavigationNextEvent());
        }
        if (!this.isPicklistValid()) {
            this.setPicklistError(PICKLIST_ERROR_MESSAGE);
        }
        if (!this.isTextareaValid()) {
            this.setTextareaError(TEXTAREA_ERROR_MESSAGE);
        }
    }
    picklistElement() {
        return this.template.querySelector('c-picklist');
    }
    textareaElement() {
        return this.template.querySelector('c-textarea');
    }

    setPicklistError(message) {
        const picklist = this.picklistElement();
        if (picklist) {
            picklist.errorText = message;
            picklist.validationHandler();
        }
    }
    resetPicklistError() {
        this.setPicklistError('');
    }
    setTextareaError(message, validationError = true) {
        const textarea = this.textareaElement();
        if (textarea) {
            textarea.errorText = message;
            textarea.validationHandler();
            this.textAreaValidationError = validationError;
        }
    }
    resetTextareaError() {
        this.setTextareaError('', false);
    }
    isPicklistValid() {
        if (this.isPicklistRequired && (!this.value || this.value === '')) {
            return false;
        } else {
            return true;
        }
    }
    isTextareaValid() {
        if (this.isTextareaRequired && (!this.inputText || this.inputText.trim() === '')) {
            return false;
        } else {
            return true;
        }
    }
}
