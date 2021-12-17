import { LightningElement, api } from 'lwc';

export default class ListFiltersButton extends LightningElement {
    @api header;
    @api activeFilters;
    @api filters;
    openFilters() {
        this.template.querySelector('c-list-filters').openFilters();
    }
}
