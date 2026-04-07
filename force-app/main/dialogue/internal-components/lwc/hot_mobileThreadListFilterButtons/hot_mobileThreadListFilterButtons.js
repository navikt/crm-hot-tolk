import { LightningElement } from 'lwc';

export default class hot_mobileThreadListFilterButtons extends LightningElement {
    activeTab = 'all';

    get threadFilterButtonType() {
        const active = this.activeTab;
        const buttons = this.threadsFilterButtons;

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

    threadsFilterButtons = [
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
        }
    ];

    handleFilterButtonClick(event) {
        this.setActiveTab(event);
        const eventToSend = new CustomEvent('filterbuttonclick', {
            detail: event.target.value
        });
        this.dispatchEvent(eventToSend);
    }
    handleFilterSelectChange(event) {
        const eventToSend = new CustomEvent('filterbuttonclick', {
            detail: event.detail.name
        });
        this.dispatchEvent(eventToSend);
    }

    renderedCallback() {
        this.updateTabStyle();
    }

    setActiveTab(event) {
        const selected = event.target.dataset.id;
        if (selected && this.activeTab !== selected) {
            this.activeTab = selected;
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
