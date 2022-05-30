import { LightningElement, api } from 'lwc';

export default class CommunityTextarea extends LightningElement {
    @api maxLength;
    errorMessage = 'Tekstfeltet kan ikke være tomt';
    message;
    errorState = false;

    handleChange(event) {
        this.message = event.target.value;
        this.publishMessage();
    }

    handleMessage(event) {
        this.errorState = false;
        this.message = event.target.value;
        this.processMessageStyling();
    }

    processMessageStyling() {
        this.mirror.textContent = this.message + '\n s';
        this.tekstboks.style.height = this.mirror.offsetHeight + 'px';
        if (this.limitCharacters) {
            let counter = this.template.querySelector('.remainingCounter');
            counter.ariaLive = this.remainingCharacters <= 20 ? 'polite' : 'off';
        }
    }

    publishMessage() {
        const textChangedEvent = new CustomEvent('textchanged', {
            detail: this.message
        });
        this.dispatchEvent(textChangedEvent);
    }

    @api
    clearText() {
        this.message = '';
        this.tekstboks.value = this.message;
        this.publishMessage();
        this.processMessageStyling();
    }

    get remainingCharacters() {
        return this.message ? this.maxLength - this.message.length : this.maxLength;
    }

    get remainingCharacterText() {
        return (
            'Du har ' +
            Math.abs(this.remainingCharacters) +
            ' tegn ' +
            (this.remainingCharacters < 0 ? 'for mye' : 'igjen')
        );
    }

    get remainingCharacterClass() {
        return (
            'navds-textarea__counter navds-body-short remainingCounter' +
            (this.remainingCharacters < 0 ? ' navds-textarea__counter--error' : '')
        );
    }

    get labelText() {
        return 'Tekstområde' + (this.limitCharacters ? ' med plass til ' + this.maxLength + ' tegn' : '');
    }

    get limitCharacters() {
        return this.maxLength !== 0 && this.maxLength != null;
    }

    get tekstboks() {
        return this.template.querySelector('.tekstboks');
    }

    get mirror() {
        return this.template.querySelector('.mirror');
    }

    checkError() {
        if (!this.message || this.message.length === 0) {
            this.errorState = true;
            this.errorMessage = 'Tekstfeltet kan ikke være tomt.';
        } else if (this.limitCharacters && this.message.length > this.maxLength) {
            this.errorState = true;
            this.errorMessage = 'Tekstefeltet kan ikke ha for mange tegn.';
        } else {
            this.errorState = false;
        }
    }

    get wrapperClass() {
        return 'navds-form-field navds-form-field--medium' + (this.errorState ? ' navds-textarea--error' : '');
    }

    @api
    focus() {
        this.tekstboks.focus();
    }
}
