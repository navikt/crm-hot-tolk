import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class Hot_frilanstolkServiceAppointmentLists extends NavigationMixin(LightningElement) {
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
        console.log('baseURL: ', baseURL);
        if (this.urlStateParameterList !== '') {
            baseURL += '?list=' + this.urlStateParameterList;
        }
        window.history.pushState({ path: baseURL }, '', baseURL);
    }

    // TODO: When going back with browser button - set active tab
    // TODO: When going back with link - does not work
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
        console.log('res.id: ', res.id);
        console.log('res.list: ', res.tab);
        console.log('this.activeTab: ', this.activeTab);
        if (res.id && this.activeTab === res.tab) {
            console.log('go back to list view');
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
