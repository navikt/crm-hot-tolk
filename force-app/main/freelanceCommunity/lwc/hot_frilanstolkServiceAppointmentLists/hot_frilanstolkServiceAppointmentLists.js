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

    @track tabs = [
        { name: 'open', label: 'Ledige oppdrag', selected: false },
        { name: 'interested', label: 'Påmeldte oppdrag', selected: false },
        { name: 'my', label: 'Mine oppdrag', selected: false },
        { name: 'wageClaim', label: 'Ledig på lønn', selected: false }
    ];

    @track tabMap = {
        open: false,
        interested: false,
        my: false,
        wageClaim: false
    };

    setActiveTabMobile(event) {
        this.setActiveTab({ target: { dataset: { id: event.detail.name } } });
    }

    setActiveTab(event) {
        for (let tab of this.tabs) {
            tab.selected = false;
            this.tabMap[tab.name] = false;
            if (tab.name === event.target.dataset.id) {
                tab.selected = true;
                this.urlStateParameterList = tab.name;
                this.activeTab = tab.name;
                this.tabMap[tab.name] = true;
            }
        }
        this.updateTabStyle();
        this.updateURL();
    }

    renderedCallback() {
        this.updateTabStyle();
    }
    updateTabStyle() {
        this.template.querySelectorAll('button.tab').forEach((element) => {
            element.classList.remove('tab_active');
            if (element.dataset.id === this.activeTab) {
                element.classList.add('tab_active');
            }
        });
    }
}
