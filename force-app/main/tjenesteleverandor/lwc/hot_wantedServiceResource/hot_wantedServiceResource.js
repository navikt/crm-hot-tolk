import { LightningElement, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';

const FLOW_API_NAME = 'HOT_RegisterWantedServiceResource';

export default class Hot_wantedServiceResource extends LightningElement {
    recordId;
    showFlow = false;
    flowStarted = false;

    @wire(CurrentPageReference)
    handlePageReference(pageReference) {
        this.recordId = pageReference?.state?.c__recordId;
    }

    handleWantedInterpreter() {
        if (this.showFlow) {
            this.showFlow = false;
            this.flowStarted = false;
            return;
        }

        if (!this.recordId) {
            return;
        }

        this.showFlow = true;
    }

    get wantedInterpreterButtonLabel() {
        return this.showFlow ? 'Avbryt' : 'Ønsk en tolk';
    }

    renderedCallback() {
        if (!this.showFlow || this.flowStarted) {
            return;
        }

        const flow = this.template.querySelector('lightning-flow');
        if (flow) {
            this.flowStarted = true;
            flow.startFlow(FLOW_API_NAME, [
                {
                    name: 'recordId',
                    type: 'String',
                    value: this.recordId
                }
            ]);
        }
    }
}
