import { LightningElement, api } from 'lwc';

export default class Hot_threadListCard extends LightningElement {
    @api thread;

    handleButtonClick(event) {
        const threadId = event.currentTarget.value;
        this.dispatchEvent(new CustomEvent('threadbuttonclick', { detail: threadId }));
    }
}
