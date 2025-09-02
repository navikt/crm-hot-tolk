import { LightningElement, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';

export default class Hot_freelanceServiceAppointmentWrapper_v2 extends NavigationMixin(LightningElement) {
    filters = [];
    records = [];
    checkedRows = [];
    isWantedList = false;

    activeTab = 'open';

    tabs = [
        { name: 'open', label: 'Ledige oppdrag', selected: false },
        { name: 'interested', label: 'Påmeldte oppdrag', selected: false },
        { name: 'my', label: 'Mine oppdrag', selected: false },
        { name: 'wageClaim', label: 'Ledig på lønn', selected: false },
        { name: 'wanted', label: 'Oppdrag du er ønsket til', selected: false }
    ];

    get tabMap() {
        return {
            open: this.activeTab === 'open',
            interested: this.activeTab === 'interested',
            my: this.activeTab === 'my',
            wageClaim: this.activeTab === 'wageClaim',
            wanted: this.activeTab === 'wanted'
        };
    }

    get showFilterButton() {
        return !this.isWantedList && !this.isDetails;
    }

    get showTabsAndLineBreak() {
        return !this.isDetails;
    }

    get showOpenTabReleaseButton() {
        return this.activeTab === 'open';
    }

    handleFilters(event) {
        this.filters = event.detail;
    }
    handleRecords(event) {
        this.records = event.detail;
    }
    handleRowChecked(event) {
        this.checkedRows = event.detail;
    }

    recordId;
    urlStateParameters;
    fromUrl;
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference && Object.keys(currentPageReference.state).length > 0) {
            this.urlStateParameters = { ...currentPageReference.state };
            this.updateTab({ target: { dataset: { id: this.urlStateParameters.list } } });
            this.fromUrl = this.urlStateParameters.from;
            this.recordId = this.urlStateParameters.id;
        } else {
            if (sessionStorage.getItem('activeTabFreelanceHome') != null) {
                this.updateTab({ target: { dataset: { id: sessionStorage.getItem('activeTabFreelanceHome') } } });
            } else {
                this.updateTab({ target: { dataset: { id: 'open' } } });
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
            this.isWantedList = selected === 'wanted';
            sessionStorage.setItem('activeTabFreelanceHome', selected);
            this.urlStateParameterList = selected;
        }
    }

    updateTab(event) {
        for (let tab of this.tabs) {
            tab.selected = false;
            this.tabMap[tab.name] = false;
            if (tab.name === event.target.dataset.id) {
                tab.selected = true;
                this.urlStateParameterList = tab.name;
                this.activeTab = tab.name;
                sessionStorage.setItem('activeTabFreelanceHome', this.activeTab);
                this.tabMap[tab.name] = true;
                if (this.activeTab == 'wanted') {
                    this.isWantedList = true;
                } else {
                    this.isWantedList = false;
                }
            }
        }
        this.updateTabStyle();
    }

    urlStateParameterList = '';
    updateURL() {
        let baseURL = window.location.protocol + '//' + window.location.host + window.location.pathname;
        if (this.urlStateParameterList) {
            baseURL += '?list=' + this.urlStateParameterList;
        }
        window.history.pushState({ path: baseURL }, '', baseURL);
    }

    goBack() {
        let res = this.template.querySelector('[data-name="' + this.activeTab + '"]').goBack();
        if (!res.id) {
            if (this.fromUrl == 'mine-varsler') {
                this[NavigationMixin.Navigate]({
                    type: 'comm__namedPage',
                    attributes: {
                        pageName: 'mine-varsler'
                    }
                });
            } else {
                this[NavigationMixin.Navigate]({
                    type: 'comm__namedPage',
                    attributes: {
                        pageName: 'home'
                    }
                });
            }
        }
        if (res.id && this.activeTab === res.tab) {
            this.updateURL();
        }
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

    applyFilter(event) {
        this.filters = event.detail.filterArray;
        let recordListLength = this.template.querySelector('[data-name="' + this.activeTab + '"]').applyFilter(event);
        return recordListLength;
    }

    sendFilteredRecordsLength(event) {
        let recordListLength = this.applyFilter(event);
        this.template.querySelector('c-list-filters-button').setFilteredRecordsLength(recordListLength);
    }

    isDetails = false;
    handleDetails(event) {
        this.isDetails = event.detail;
        if (!this.isDetails) {
            this.recordId = undefined;
        }
    }

    sendFilters() {
        const eventToSend = new CustomEvent('sendfilters', { detail: this.filters });
        this.dispatchEvent(eventToSend);
    }

    isRemoveReleasedTodayButtonHidden = true;
    isReleasedTodayButtonHidden = false;
    checkedServiceAppointments = [];
    releasedTodayFilter() {
        this.checkedServiceAppointments = [];
        this.noReleasedToday = false;
        const d = new Date();
        let year = d.getFullYear();
        let day = d.getDate();
        let month = d.getMonth() + 1;
        month = month < 10 ? '0' + month : month;
        day = day < 10 ? '0' + day : day;
        const formattedDate = `${year}-${month}-${day}`;
        this.filters[5].value[0].value = formattedDate;

        this.sendFilters();
        this.applyFilter({ detail: { filterArray: this.filters, setRecords: true } });
        this.isReleasedTodayButtonHidden = true;
        this.isRemoveReleasedTodayButtonHidden = false;
    }

    removeReleasedTodayFilter() {
        this.checkedServiceAppointments = [];
        this.filters[5].value[0].value = '';
        this.sendFilters();
        this.applyFilter({ detail: { filterArray: this.filters, setRecords: true } });
        this.isReleasedTodayButtonHidden = false;
        this.isRemoveReleasedTodayButtonHidden = true;
    }
}
