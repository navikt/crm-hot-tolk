import { LightningElement, api } from 'lwc';

export default class Hot_threadListCard extends LightningElement {
    @api thread;

    handleButtonClick(event) {
        const threadId = event.currentTarget.value;
        this.dispatchEvent(new CustomEvent('threadbuttonclick', { detail: threadId }));
    }
    get lastMessageAria() {
        return 'Siste melding sendt: ${this.thread.lastMessageSentFormatted}';
    }

    get appointmentStartAria() {
        return 'Oppdragsstart: ${this.thread.appointmentStartFormatted}';
    }

    get threadTypeAria() {
        return 'Samtale ${this.thread.threadTypeName}';
    }
}
