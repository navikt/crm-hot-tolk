import LightningModal from 'lightning/modal';
export default class DeleteConfirmationModal extends LightningModal {
    handleOkay() {
        this.close(true);
    }

    handleDeny() {
        this.close(false);
    }
}
