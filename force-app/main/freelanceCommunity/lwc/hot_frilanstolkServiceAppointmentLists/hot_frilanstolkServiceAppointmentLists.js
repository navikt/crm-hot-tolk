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

    @track urlStateParameterList = '';
    updateURL() {
        let baseURL = window.location.protocol + '//' + window.location.host + window.location.pathname;
        if (this.urlStateParameterList !== '') {
            baseURL += '?list=' + this.urlStateParameterList;
        }
        window.history.pushState({ path: baseURL }, '', baseURL);
    }

    // TODO: When going back with browser button - set active tab is not working and go to home is not working
    goBack() {
        let res;
        if (this.activeTab === 'open') {
            res = this.template.querySelector('c-hot_open-service-appointments').goBack();
        } else if (this.activeTab === 'interested') {
            res = this.template.querySelector('c-hot_interested-resources-list').goBack();
        } else if (this.activeTab === 'my') {
            res = this.template.querySelector('c-hot_my-service-appointments').goBack();
        } else if (this.activeTab === 'wageClaim') {
            res = this.template.querySelector('c-hot_wage-claim-list').goBack();
        }
        if (res.id === '') {
            this.updateURL();
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    pageName: 'home'
                }
            });
        }
        if (res.id && this.activeTab === res.tab) {
            this.updateURL();
            this.template.querySelector('lightning-tabset').activeTabValue = res.tab;
        }
    }

    @track activeTab;
    setActiveTab(event) {
        this.activeTab = event.target.value;
        this.urlStateParameterList = this.activeTab;
        this.updateURL();
    }
}
