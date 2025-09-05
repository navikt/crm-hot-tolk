import { LightningElement, api } from 'lwc';
import { FlowAttributeChangeEvent, FlowNavigationFinishEvent } from 'lightning/flowSupport';

export default class Hot_infoParagraphFlow extends LightningElement {
    @api label;
    @api text;

    handleFinish() {
        this.dispatchEvent(new FlowNavigationFinishEvent());
    }
}
