import { LightningElement, api } from 'lwc';

export default class Hot_threadListCard extends LightningElement {
    @api thread;

    handleButtonClick(event) {
        const threadId = event.currentTarget.value;
        this.dispatchEvent(new CustomEvent('threadbuttonclick', { detail: threadId }));
    }
    get fullAriaLabel() {
        return (
            this.thread.statusText +
            '. Samtale ' +
            this.thread.threadTypeName +
            '. Tema: ' +
            this.thread.HOT_Subject__c +
            '. ' +
            'Siste melding sendt: ' +
            this.thread.lastMessageSentFormatted +
            '. Oppdragsstart: ' +
            this.thread.appointmentStartFormatted +
            '.'
        );
    }
}
