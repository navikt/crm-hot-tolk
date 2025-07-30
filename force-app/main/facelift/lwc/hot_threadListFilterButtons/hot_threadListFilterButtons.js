import { LightningElement, api } from 'lwc';

export default class Hot_threadListFilterButtons extends LightningElement {
    @api isFreelanceView = false;

    get threadFilterButtonType() {
        if (this.isFreelanceView) {
            return this.freelanceThreadsFilterButtons;
        } else {
            return this.userThreadsFilterButtons;
        }
    }

    freelanceThreadsFilterButtons = [
        {
            label: 'Alle',
            value: ''
        },
        {
            label: 'Med formidler',
            value: 'HOT_TOLK-FORMIDLER'
        },
        {
            label: 'Med bruker',
            value: 'HOT_BRUKER-TOLK'
        },
        {
            label: 'Med medtolk og bruker',
            value: 'HOT_TOLK-TOLK'
        },
        {
            label: 'Med ressurskontor',
            value: 'HOT_TOLK-RESSURSKONTOR'
        }
    ];
    userThreadsFilterButtons = [
        {
            label: 'Alle',
            value: ''
        },
        {
            label: 'Med formidler',
            value: 'HOT_BRUKER-FORMIDLER'
        },
        {
            label: 'Med tolk',
            value: 'HOT_BRUKER-TOLK'
        }
    ];
    handleFilterButtonClick(event) {
        const eventToSend = new CustomEvent('filterbuttonclick', {
            detail: event.target.value
        });
        this.dispatchEvent(eventToSend);
    }
    handleFilterSelectChange(event) {
        const eventToSend = new CustomEvent('filterbuttonclick', {
            detail: event.target.value
        });
        this.dispatchEvent(eventToSend);
    }
}
