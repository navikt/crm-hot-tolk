import { LightningElement, api } from 'lwc';

export default class CrmRedactText extends LightningElement {
    _originalValue = '';
    _changes = [];
    _changesPosition = -1;
    _textAreaclass = 'redactTextArea slds-textarea slds-text-color_default';
    _textAreaStyle = 'resize: none; overflow: hidden; overflow:hidden; ';
    hasRendered = false;

    @api get textToRedact() {
        return this._originalValue;
    }

    set textToRedact(value) {
        this.resetTextToRedact(value);
    }

    set textAreaClass(value) {
        this._textAreaclass = value ? `redactTextArea ${value}` : 'redactTextArea';
    }

    @api get textAreaClass() {
        return this._textAreaclass;
    }

    @api get redactedText() {
        return this.redactedValue;
    }

    get redactedValue() {
        return this._changes[this._changesPosition] ? this._changes[this._changesPosition] : this.textToRedact;
    }

    renderedCallback() {
        if (this.hasRendered === false) {
            this.hasRendered = true;
            const element = this.template.querySelector('.redactTextArea');
            element.style = `${this._textAreaStyle} height:${element.scrollHeight}px;`;
        }
    }

    @api undoChanges() {
        if (this.canUndo) {
            this._changesPosition--;
            this.dispatchRedactedEvent();
        }
    }

    @api redoChanges() {
        if (this.canRedo) {
            this._changesPosition++;
            this.dispatchRedactedEvent();
        }
    }

    @api reset() {
        this.resetTextToRedact(this._originalValue);
    }

    get canUndoDisabled() {
        return !this.canUndo;
    }

    get canRedoDisabled() {
        return !this.canRedo;
    }

    @api get canUndo() {
        return this._changesPosition > 0;
    }

    @api get canRedo() {
        return this._changesPosition < this._changes.length - 1;
    }

    @api get hasChanges() {
        return this.canUndo;
    }

    @api addRedactedValue(value) {
        if (this.canRedo) {
            this._changes.length = this._changesPosition + 1;
        }
        this._changes.push(value);
        console.log(this._changes);

        this._changesPosition = this._changes.length - 1;
        this.dispatchRedactedEvent();
    }

    resetTextToRedact(value) {
        if (value) {
            this._changes = [];
            this._changesPosition = -1;
            this._originalValue = value;
            this.addRedactedValue(value);
        } else {
            throw new Error('Need original value!');
        }
    }

    onSelectText(event) {
        event.preventDefault();
        const len = this.redactedValue.length;
        const start = event.target.selectionStart;
        const end = event.target.selectionEnd;
        const selection = event.target.value.substring(start, end);
        const redacted = selection.replace(/\S/g, '*');

        this.addRedactedValue(this.redactedValue.slice(0, start) + redacted + this.redactedValue.slice(end, len));
    }

    dispatchRedactedEvent() {
        this.dispatchEvent(new CustomEvent('text_redacted', { detail: this.redactedValue }));
    }
}
