import { api } from 'lwc';
import LightningModal from 'lightning/modal';

export default class HOT_ConfirmationModal extends LightningModal {
    @api headline;
    @api message;
    @api primaryLabel = 'Confirm';
    @api secondaryLabel = 'Cancel';

    handlePrimaryAction() {
        this.close('primary');
    }

    handleSecondaryAction() {
        this.close('secondary');
    }
}
