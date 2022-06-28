import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class Hot_frilanstolkServiceAppointmentLists extends NavigationMixin(LightningElement) {
    // TODO: Send records from active tab to filter when pressed
    @track filters = [];
    breadcrumbs = [
        {
            label: 'Tolketjenesten',
            href: ''
        },
        {
            label: 'Oppdrag',
            href: 'mine-oppdrag'
        }
    ];

    connectedCallback() {
        this.setActiveTab({ target: { dataset: { id: 'open' } } });
    }

    @track urlStateParameterList = '';
    updateURL() {
        let baseURL = window.location.protocol + '//' + window.location.host + window.location.pathname;
        if (this.urlStateParameterList !== '') {
            baseURL += '?list=' + this.urlStateParameterList;
        }
        window.history.pushState({ path: baseURL }, '', baseURL);
    }

    goBack() {
        let res = this.template.querySelector('[data-name="' + this.activeTab + '"]').goBack();
        if (res.id === '') {
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    pageName: 'home'
                }
            });
        }
        if (res.id && this.activeTab === res.tab) {
            this.updateURL();
        }
    }

    @track tabs = {
        open: false,
        interested: false,
        my: false,
        wageClaim: false
    };

    setActiveTab(event) {
        for (let tab in this.tabs) {
            this.tabs[tab] = false;
            if (tab === event.target.dataset.id) {
                this.tabs[tab] = true;
                this.urlStateParameterList = tab;
                this.activeTab = tab;
            }
        }
        this.updateURL();
    }
}
