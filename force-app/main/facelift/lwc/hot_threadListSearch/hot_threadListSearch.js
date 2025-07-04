import { LightningElement, api } from 'lwc';

export default class Hot_threadListSearch extends LightningElement {
    @api isFreelanceView = false;

    labelText = 'Søk';

    handleSearchChange(event) {
        const eventToSend = new CustomEvent('searchchange', {
            detail: event.detail
        });
        this.dispatchEvent(eventToSend);
    }
    get placeholderText() {
        if (this.isFreelanceView) {
            return 'Søk på tittel på oppdraget';
        } else {
            return 'Søk på tittel på bestilling';
        }
    }
}
