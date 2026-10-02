import { LightningElement, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';

const ACTIVE_TAB_STORAGE_KEY = 'activeTabTjenesteleverandorHome';
const DEFAULT_TAB = 'transferred';

export default class Hot_tjenesteleverandorServiceappointmentWrapper extends NavigationMixin(LightningElement) {
    activeTab = DEFAULT_TAB;
    recordId;
    filters = [];

    tabs = [
        { name: 'transferred', label: 'Overførte oppdrag' },
        { name: 'accepted', label: 'Aksepterte oppdrag' }
    ];

    get tabMap() {
        return this.tabs.map((tab) => {
            const isActive = tab.name === this.activeTab;
            return {
                ...tab,
                selected: isActive,
                className: isActive ? 'tab tab-button tab-active' : 'tab tab-button',
                ariaSelected: isActive ? 'true' : 'false',
                ariaControls: `tabpanel-${tab.name}`,
                ariaId: `tab-${tab.name}`,
                ariaLabel: tab.label
            };
        });
    }

    @wire(CurrentPageReference)
    handlePageReference(pageReference) {
        const storedTab = sessionStorage.getItem(ACTIVE_TAB_STORAGE_KEY);
        this.selectTab(pageReference?.state?.list || storedTab || DEFAULT_TAB);
        this.recordId = pageReference?.state?.id;
    }

    setActiveTab(event) {
        this.selectTab(event.target.dataset.id, true);
    }

    setActiveTabMobile(event) {
        this.selectTab(event.detail.name, true);
    }

    handleFilters(event) {
        this.filters = event.detail;
    }

    applyFilter(event) {
        this.filters = event.detail.filterArray;
        return this.template.querySelector(`[data-name="${this.activeTab}"]`)?.applyFilter(event) ?? 0;
    }

    sendFilteredRecordsLength(event) {
        const filteredRecordsLength = this.applyFilter(event);
        this.template.querySelector('c-list-filters-button')?.setFilteredRecordsLength(filteredRecordsLength);
    }

    selectTab(tabName, updateUrl = false) {
        if (!this.tabs.some((tab) => tab.name === tabName)) {
            return;
        }

        if (this.activeTab !== tabName) {
            this.filters = [];
        }
        this.activeTab = tabName;
        sessionStorage.setItem(ACTIVE_TAB_STORAGE_KEY, tabName);
        if (updateUrl) {
            this.updateURL();
        }
    }

    updateURL() {
        const baseURL = `${window.location.protocol}//${window.location.host}${window.location.pathname}?list=${this.activeTab}`;
        window.history.pushState({ path: baseURL }, '', baseURL);
    }

    get isTransferredTab() {
        return this.activeTab === 'transferred';
    }

    get isAcceptedTab() {
        return this.activeTab === 'accepted';
    }
}
