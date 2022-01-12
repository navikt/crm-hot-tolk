import { LightningElement, api } from 'lwc';

export default class ListFiltersButton extends LightningElement {
    @api header;
    @api activeFilters;
    @api filters;

    openFilters() {
        if (window.screen.width > 576) {
            const eventToSend = new CustomEvent('opendesktopfilters', { detail: 'opendesktopfilters' });
            this.dispatchEvent(eventToSend);
        } else {
            this.template.querySelector('c-list-filters').openFilters();
        }
    }
    applyFilter(event) {
        console.log('listfiltersbutton applyfilter');
        const eventToSend = new CustomEvent('applyfilter', { detail: event.detail });
        this.dispatchEvent(eventToSend);
    }
}
