import { LightningElement, api } from 'lwc';

export default class ListFilters extends LightningElement {
    @api header;
    @api choices;

    isOpen = false;
    openFilters() {
        this.isOpen = true;
    }
    closeFilters() {
        this.isOpen = false;
    }
    applyFilter() {
        //Send filter config to wrapper.
        this.closeFilters();
    }
}
