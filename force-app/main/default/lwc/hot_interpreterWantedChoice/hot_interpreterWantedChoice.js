import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { RefreshEvent } from 'lightning/refresh';
import { MessageContext, publish } from 'lightning/messageService';
import getWantedResource from '@salesforce/apex/HOT_InterpreterWantedChoiceController.getWantedResource';
import respond from '@salesforce/apex/HOT_InterpreterWantedChoiceController.respond';
import INTEREST_REGISTERED_CHANNEL from '@salesforce/messageChannel/HOT_ServiceAppointmentInterestRegistered__c';

export default class Hot_interpreterWantedChoice extends LightningElement {
    @api recordId;

    wantedState;
    wantedResource;
    errorMessage;
    isSaving = false;

    @wire(MessageContext)
    messageContext;

    @wire(getWantedResource, { serviceAppointmentId: '$recordId' })
    wiredWantedResource(result) {
        this.wantedState = result;
        if (result.data) {
            this.wantedResource = result.data[0];
            this.errorMessage = undefined;
        } else if (result.error) {
            this.wantedResource = undefined;
            this.showError(result.error);
        }
    }

    get wantedMessage() {
        return this.wantedResource?.HOT_Wanted_by__c
            ? `Du er ønsket til dette oppdraget av ${this.wantedResource.HOT_Wanted_by__c}`
            : 'Du er ønsket til dette oppdraget';
    }

    handleInterested() {
        return this.saveResponse('Interested');
    }

    handleDeclined() {
        return this.saveResponse('Declined');
    }

    async saveResponse(status) {
        if (this.isSaving) {
            return;
        }
        this.isSaving = true;
        this.errorMessage = undefined;
        const interestedResourceId = this.wantedResource.Id;
        const serviceAppointmentId = this.recordId;
        try {
            await respond({ interestedResourceId, status });
            this.wantedResource = undefined;
            await notifyRecordUpdateAvailable([{ recordId: interestedResourceId }, { recordId: serviceAppointmentId }]);
            if (status === 'Interested') {
                publish(this.messageContext, INTEREST_REGISTERED_CHANNEL, { serviceAppointmentId });
            }
            this.dispatchEvent(new RefreshEvent());
            await refreshApex(this.wantedState);
        } catch (error) {
            this.showError(error);
        } finally {
            this.isSaving = false;
        }
    }

    showError(error) {
        this.errorMessage = error.body?.message || error.message || 'Kunne ikke hente eller lagre svaret. Prøv igjen.';
    }
}
