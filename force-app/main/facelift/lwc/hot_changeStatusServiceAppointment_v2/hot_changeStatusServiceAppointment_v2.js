import { LightningElement, api } from 'lwc';
import {
    FlowAttributeChangeEvent,
    FlowNavigationBackEvent,
    FlowNavigationNextEvent,
    FlowNavigationPauseEvent,
    FlowNavigationFinishEvent
} from 'lightning/flowSupport';

export default class Hot_changeStatusServiceAppointment_v2 extends LightningElement {
    @api label;
    @api value;

    @api statusDekketLabel;
    @api statusAvlystLabel;
    @api statusTolkAvlystLabel;

    @api statusDekketValue;
    @api statusAvlystValue;
    @api statusTolkAvlystValue;

    get radiobuttons() {
        return [
            this.statusDekketValue ? { label: this.statusDekketLabel, value: this.statusDekketValue } : null,
            this.statusAvlystValue ? { label: this.statusAvlystLabel, value: this.statusAvlystValue } : null,
            this.statusTolkAvlystValue ? { label: this.statusTolkAvlystLabel, value: this.statusTolkAvlystValue } : null
        ].filter((r) => r !== null);
    }

    handleRequestTypeChange(event) {
        const detail = event.detail;
        if (!Array.isArray(detail)) return;

        const checkedRadio = detail.find((r) => r.checked);
        this.value = checkedRadio ? checkedRadio.value : null;

        this.dispatchEvent(new FlowAttributeChangeEvent('value', this.value));
    }
}
