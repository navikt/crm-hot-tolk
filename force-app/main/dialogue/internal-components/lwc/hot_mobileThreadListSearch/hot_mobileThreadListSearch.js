import { LightningElement } from 'lwc';

export default class hot_mobileThreadListSearch extends LightningElement {
    handleSearchChange(event) {
        const eventToSend = new CustomEvent('searchchange', {
            detail: event.detail
        });
        this.dispatchEvent(eventToSend);
    }
    get labelText() {
        return 'Søk på tema på oppdraget';
    }
}
