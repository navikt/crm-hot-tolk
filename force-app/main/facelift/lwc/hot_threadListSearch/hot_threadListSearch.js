import { LightningElement, api } from 'lwc';

export default class Hot_threadListSearch extends LightningElement {
    @api isFreelanceView = false;

    handleSearchChange(event) {
        const eventToSend = new CustomEvent('searchchange', {
            detail: event.detail
        });
        this.dispatchEvent(eventToSend);
    }
    get labelText() {
        if (this.isFreelanceView) {
            return 'Søk på tema på oppdraget';
        } else {
            return 'Søk på tema på bestilling';
        }
    }
}
