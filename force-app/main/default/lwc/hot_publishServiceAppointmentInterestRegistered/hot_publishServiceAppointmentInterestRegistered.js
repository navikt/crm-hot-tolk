import { LightningElement, api, wire } from 'lwc';
import { MessageContext, publish } from 'lightning/messageService';
import { FlowNavigationFinishEvent } from 'lightning/flowSupport';
import INTEREST_REGISTERED_CHANNEL from '@salesforce/messageChannel/HOT_ServiceAppointmentInterestRegistered__c';

export default class Hot_publishServiceAppointmentInterestRegistered extends LightningElement {
    @api serviceAppointmentId;
    @api availableActions = [];

    hasFinished = false;
    hasPublished = false;

    @wire(MessageContext)
    messageContext;

    renderedCallback() {
        if (!this.hasPublished && this.messageContext && this.serviceAppointmentId) {
            publish(this.messageContext, INTEREST_REGISTERED_CHANNEL, {
                serviceAppointmentId: this.serviceAppointmentId
            });
            this.hasPublished = true;
        }

        if (this.hasPublished && !this.hasFinished && this.availableActions.includes('FINISH')) {
            this.hasFinished = true;
            window.setTimeout(() => {
                this.dispatchEvent(new FlowNavigationFinishEvent());
            }, 0);
        }
    }
}
