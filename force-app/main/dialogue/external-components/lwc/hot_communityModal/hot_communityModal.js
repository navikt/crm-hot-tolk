import { LightningElement, api } from 'lwc';

export default class CommunityModal extends LightningElement {
    @api showModal = false;
    bufferFocus = false;

    closeModal() {
        this.showModal = false;
        this.dispatchClose();
    }

    renderedCallback() {
        if (this.bufferFocus) {
            this.focusModal();
        }
    }

    dispatchClose() {
        const closeEvent = new CustomEvent('modalclosed', {
            detail: false
        });
        this.dispatchEvent(closeEvent);
    }

    @api
    focusModal() {
        const modal = this.template.querySelector('.modal');
        if (modal) {
            this.bufferFocus = false;
            modal.focus();
        } else {
            this.bufferFocus = true;
        }
    }

    @api
    focusLoop() {
        const modalFocusElement = this.template.querySelector('.modalFocus');
        modalFocusElement.focus();
    }
}
