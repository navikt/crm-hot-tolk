import { LightningElement, api } from 'lwc';

export default class RecordListElement extends LightningElement {
    @api record;
    @api recordId;
    @api isLast;

    handleOnRowClick() {
        const eventToSend = new CustomEvent('rowclick', { detail: this.recordId });
        this.dispatchEvent(eventToSend);
    }
    get classList() {
        let classString = 'row-element';
        if (this.isLast) {
            classString += ' row-element--last';
        }
        return classString;
    }
}
