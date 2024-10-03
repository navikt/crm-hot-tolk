import LightningModal from 'lightning/modal';
import ConfimationModal2 from 'c/hot_calendar_absence_modal_confirmation_2';

export default class Hot_Calendar_Absence_Modal_Confirmation extends LightningModal {
    async handleOkay() {
        const isConfirmation = await ConfimationModal2.open();
        if (isConfirmation) {
            console.log('confirmation');
            this.close('resultat string');
        } else if (!isConfirmation) {
            console.log('not confirmation');
        }
    }
    handleDeny() {
        const isConfirm = false;
        this.close(isConfirm);
    }
}
