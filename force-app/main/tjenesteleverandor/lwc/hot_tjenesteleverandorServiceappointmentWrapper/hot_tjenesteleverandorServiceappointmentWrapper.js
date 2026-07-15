import { LightningElement, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';

export default class Hot_tjenesteleverandorServiceappointmentWrapper extends NavigationMixin(LightningElement) {
    activeTab = 'transferred';
    records = [];
    checkedRows = [];

    tabs = [
        { name: 'transferred', label: 'Overførte oppdrag' },
        { name: 'accepted', label: 'Aksepterte oppdrag' }
    ];

    get tabMap() {
        return this.tabs.map((tab) => {
            const isActive = tab.name === this.activeTab;
            return {
                ...tab,
                isActive,
                ariaSelected: isActive ? 'true' : 'false',
                ariaControls: 'tabpanel-' + tab.name,
                ariaId: 'tab-' + tab.name,
                ariaLabel: tab.label
            };
        });
    }

    get showTabsAndLineBreak() {
        return !this.isDetails;
    }

    handleRecords(event) {
        this.records = event.detail;
    }
    handleRowChecked(event) {
        this.checkedRows = event.detail;
    }

    isDetails = false;
    handleDetails(event) {
        this.isDetails = event.detail;
        if (!this.isDetails) {
            this.recordId = undefined;
        }
    }

    recordId;
    urlStateParameters;
    urlStateParameterList = '';

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference && Object.keys(currentPageReference.state).length > 0) {
            this.urlStateParameters = { ...currentPageReference.state };
            this.updateTab({
                target: {
                    dataset: {
                        id: this.urlStateParameters.list
                    }
                }
            });
            this.recordId = this.urlStateParameters.id;
        } else {
            if (sessionStorage.getItem('activeTabTjenesteleverandorHome') != null) {
                this.updateTab({
                    target: {
                        dataset: {
                            id: sessionStorage.getItem('activeTabTjenesteleverandorHome')
                        }
                    }
                });
            } else {
                this.updateTab({
                    target: {
                        dataset: {
                            id: 'transferred'
                        }
                    }
                });
            }
        }
    }

    setActiveTabMobile(event) {
        this.setActiveTab({ target: { dataset: { id: event.detail.name } } });
    }

    setActiveTab(event) {
        const selected = event.target.dataset.id;
        if (selected && this.activeTab !== selected) {
            this.activeTab = selected;
            sessionStorage.setItem('activeTabTjenesteleverandorHome', selected);
            this.urlStateParameterList = selected;
            this.updateURL();
        }
    }

    updateTab(event) {
        for (let tab of this.tabs) {
            tab.selected = false;
            if (tab.name === event.target.dataset.id) {
                tab.selected = true;
                this.urlStateParameterList = tab.name;
                this.activeTab = tab.name;
                sessionStorage.setItem('activeTabTjenesteleverandorHome', this.activeTab);
            }
        }
        this.updateTabStyle();
    }

    updateURL() {
        let baseURL = window.location.protocol + '//' + window.location.host + window.location.pathname;
        if (this.urlStateParameterList) {
            baseURL += '?list=' + this.urlStateParameterList;
        }
        window.history.pushState({ path: baseURL }, '', baseURL);
    }

    renderedCallback() {
        this.updateTabStyle();
    }

    updateTabStyle() {
        const buttons = this.template.querySelectorAll('button.tab-button');
        buttons.forEach((button) => {
            const isActive = button.dataset.id === this.activeTab;
            button.classList.toggle('tab-active', isActive);
        });
    }

    get isTransferredTab() {
        return this.activeTab === 'transferred';
    }

    get isAcceptedTab() {
        return this.activeTab === 'accepted';
    }
}
