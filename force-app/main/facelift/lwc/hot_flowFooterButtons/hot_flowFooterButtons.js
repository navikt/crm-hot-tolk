import { LightningElement, api } from 'lwc';
import {
    FlowAttributeChangeEvent,
    FlowNavigationBackEvent,
    FlowNavigationNextEvent,
    FlowNavigationPauseEvent,
    FlowNavigationFinishEvent
} from 'lightning/flowSupport';

export default class Hot_flowFooterButtons extends LightningElement {
    @api showBack = false;
    @api showNext = false;
    @api showFinish = false;
    @api size; // medium, small, xsmall
    @api backLabel = 'Forrige';
    @api nextLabel = 'Neste';
    @api finishLabel = 'Fullfør';

    handleBack() {
        this.dispatchEvent(new FlowNavigationBackEvent());
    }

    handleNext() {
        this.dispatchEvent(new FlowNavigationNextEvent());
    }

    handleFinish() {
        this.dispatchEvent(new FlowNavigationFinishEvent());
    }
}
