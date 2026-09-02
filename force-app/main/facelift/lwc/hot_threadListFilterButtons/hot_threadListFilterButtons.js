import { LightningElement, api } from 'lwc';

export default class Hot_threadListFilterButtons extends LightningElement {
    @api isFreelanceView = false;
    @api activeTab = 'all';

    get threadFilterButtonType() {
        const active = this.activeTab;
        const buttons = this.isFreelanceView ? this.freelanceThreadsFilterButtons : this.userThreadsFilterButtons;

        return buttons.map((btn) => {
            return {
                ...btn,
                ariaSelected: btn.value === active ? 'true' : 'false',
                ariaControls: 'tab-' + btn.value,
                ariaId: 'tab-' + btn.value,
                ariaLabel: 'Vis samtaler ' + btn.label.toLowerCase()
            };
        });
    }

    freelanceThreadsFilterButtons = [
        {
            label: 'Alle',
            name: 'all',
            value: 'all',
            selected: false
        },
        {
            label: 'Med formidler',
            name: 'HOT_TOLK-FORMIDLER',
            value: 'HOT_TOLK-FORMIDLER',
            selected: false
        },
        {
            label: 'Med bruker',
            name: 'HOT_BRUKER-TOLK',
            value: 'HOT_BRUKER-TOLK',
            selected: false
        },
        {
            label: 'Med medtolk',
            name: 'HOT_TOLK-TOLK',
            value: 'HOT_TOLK-TOLK',
            selected: false
        },
        {
            label: 'Med ressurskontor',
            name: 'HOT_TOLK-RESSURSKONTOR',
            value: 'HOT_TOLK-RESSURSKONTOR',
            selected: false
        }
    ];

    userThreadsFilterButtons = [
        {
            label: 'Alle',
            name: 'all',
            value: 'all',
            selected: false
        },
        {
            label: 'Med formidler',
            name: 'HOT_BRUKER-FORMIDLER',
            value: 'HOT_BRUKER-FORMIDLER',
            selected: false
        },
        {
            label: 'Med tolk',
            name: 'HOT_BRUKER-TOLK',
            value: 'HOT_BRUKER-TOLK',
            selected: false
        }
    ];

    handleFilterButtonClick(event) {
        const selectedTab = event.target.dataset.id;

        this.setActiveTab(selectedTab);

        const eventToSend = new CustomEvent('filterbuttonclick', {
            detail: event.target.value
        });

        this.dispatchEvent(eventToSend);
    }

    handleFilterSelectChange(event) {
        this.setActiveTab(event.detail.name);

        const eventToSend = new CustomEvent('filterbuttonclick', {
            detail: event.detail.name
        });

        this.dispatchEvent(eventToSend);
    }

    renderedCallback() {
        this.updateTabStyle();
    }

    @api
    setActiveTab(tabName) {
        if (tabName && this.activeTab !== tabName) {
            this.activeTab = tabName;
            this.updateTabStyle();
        }
    }

    updateTabStyle() {
        const buttons = this.template.querySelectorAll('button.tab-button');

        buttons.forEach((button) => {
            const isActive = button.dataset.id === this.activeTab;

            button.classList.toggle('tab-active', isActive);
        });
    }
}
