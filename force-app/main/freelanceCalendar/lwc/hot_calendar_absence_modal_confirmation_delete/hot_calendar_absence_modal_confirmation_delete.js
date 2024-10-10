import LightningModal from 'lightning/modal';
export default class ConfimationModal extends LightningModal {
    handleOkay() {
        this.close(true);
    }

    handleDeny() {
        this.close(false);
    }
}
