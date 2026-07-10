import { LightningElement } from 'lwc';

export default class Hot_tjenesteleverandorServiceappointmentWrapper extends LightningElement {
    activeTab = 'transferred';

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

    setActiveTab(event) {
        const selected = event.target.dataset.id;
        if (selected && this.activeTab !== selected) {
            this.activeTab = selected;
        }
    }

    setActiveTabMobile(event) {
        this.activeTab = event.detail.name;
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
