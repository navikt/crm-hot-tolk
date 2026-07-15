import { api } from 'lwc';
import LightningModal from 'lightning/modal';

export default class Hot_flowModal extends LightningModal {
    @api flowApiName;
    @api flowLabel;
    @api recordId;

    connectedCallback() {
        // Start the flow when the modal opens
        setTimeout(() => {
            const flow = this.template.querySelector('lightning-flow');
            if (flow && this.flowApiName) {
                flow.startFlow(this.flowApiName, [
                    {
                        name: 'recordId',
                        type: 'String',
                        value: this.recordId
                    }
                ]);
            }
        }, 0);
    }

    handleStatusChange(event) {
        const status = event.detail.status;
        if (status === 'FINISHED' || status === 'FINISHED_SCREEN') {
            // Close the modal and return the flow status
            this.close(status);
        }
    }

    handleClose() {
        // Close the modal without returning a value
        this.close();
    }
}
