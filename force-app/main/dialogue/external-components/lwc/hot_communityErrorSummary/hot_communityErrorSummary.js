import { LightningElement, api } from 'lwc';

export default class CommunityErrorSummary extends LightningElement {
    @api errorList;
    @api originalTitle = 'For å sende melding må du rette følgende:';
    bufferFocus = false;

    @api focusHeader() {
        if (this.showWarnings) {
            let heading = this.template.querySelector('.navds-error-summary__heading');
            heading.focus();
        } else {
            this.bufferFocus = true;
        }
    }

    renderedCallback() {
        if (this.bufferFocus) {
            let heading = this.template.querySelector('.navds-error-summary__heading');
            heading.focus();
            this.bufferFocus = false;
        }
    }

    handleLinkClick(event) {
        const clickedEvent = new CustomEvent('clickedevent', {
            detail: event.detail
        });
        this.dispatchEvent(clickedEvent);
    }

    get showWarnings() {
        return this.errorList.errors.length !== 0;
    }

    get title() {
        return (!this.errorList.title || this.errorList.title === 0) ? this.errorList.title : this.originalTitle;
    }
}
