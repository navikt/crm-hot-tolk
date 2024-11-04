import { LightningElement, api, track } from 'lwc';
import LightningModal from 'lightning/modal';
import updateInterestedResource from '@salesforce/apex/HOT_wantedSRListController.updateInterestedResource';
import declineInterestedResource from '@salesforce/apex/HOT_wantedSRListController.declineInterestedResource';

export default class Hot_wantedServiceAppointmentsListModal extends LightningModal {
    @api serviceAppointment;
    @api serviceResourceId;
    @track processMessage;
    @track processMessageResult;
    @track errorMessage;
    @track spin = false;
    @track submittedSuccess = false;
    @track submittedError = false;
    @track isDetails = true;
    actionType; // Local variable to keep track of action type

    // Method to handle accepting interest
    acceptInterest() {
        this.actionType = 'acceptInterest';
        this.processMessage = 'Melder interesse...';
        this.handleAction();
    }

    // Method to handle declining interest
    declineInterest() {
        this.actionType = 'declineInterest';
        this.processMessage = 'Avslår interesse...';
        this.handleAction();
    }

    // General method to handle both actions
    handleAction() {
        this.isDetails = false;
        this.spin = true;

        let actionPromise;
        if (this.actionType === 'acceptInterest') {
            actionPromise = updateInterestedResource({
                saId: this.serviceAppointment.Id,
                srId: this.serviceResourceId
            });
        } else if (this.actionType === 'declineInterest') {
            actionPromise = declineInterestedResource({
                saId: this.serviceAppointment.Id,
                srId: this.serviceResourceId
            });
        }

        actionPromise
            .then(() => {
                this.spin = false;
                this.submittedSuccess = true;
                this.processMessageResult =
                    this.actionType === 'acceptInterest' ? 'Interesse er meldt.' : 'Avslått interesse for oppdraget';
                // Optional: refresh data if needed
                // refreshApex(this.wiredAllServiceAppointmentsResult);
            })
            .catch((error) => {
                this.spin = false;
                this.submittedError = true;
                this.errorMessage = error.body ? error.body.message : error.message;
            });
    }

    // Method to close the modal
    closeModal() {
        this.close({
            success: this.submittedSuccess,
            error: this.submittedError
        });
    }
}
