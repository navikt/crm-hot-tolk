import { LightningElement, api } from 'lwc';
import {
    FlowAttributeChangeEvent,
    FlowNavigationBackEvent,
    FlowNavigationNextEvent,
    FlowNavigationPauseEvent,
    FlowNavigationFinishEvent
} from 'lightning/flowSupport';

export default class Hot_changeStatusServiceAppointment_v2 extends LightningElement {
    @api groupLabel;
    @api value;

    @api rbOneLabel;
    @api rbOneValue;
    @api rbTwoLabel;
    @api rbTwoValue;
    @api rbThreeLabel;
    @api rbThreeValue;

    get radiobuttons() {
        return [
            this.rbOneValue ? { label: this.rbOneLabel, value: this.rbOneValue } : null,
            this.rbTwoValue ? { label: this.rbTwoLabel, value: this.rbTwoValue } : null,
            this.rbThreeValue ? { label: this.rbThreeLabel, value: this.rbThreeValue } : null
        ].filter((r) => r !== null);
    }

    // Updates the Flow variable "value" when a radio button is selected
    handleRequestTypeChange(event) {
        const detail = event.detail;
        if (!Array.isArray(detail)) return;

        const selectedRadio = detail.find((r) => r.checked);
        this.value = selectedRadio ? selectedRadio.value : null;

        this.dispatchEvent(new FlowAttributeChangeEvent('value', this.value));
    }

    // Dispatch the Flow "Next" event
    handleNext() {
        this.dispatchEvent(new FlowNavigationNextEvent());
    }
}
