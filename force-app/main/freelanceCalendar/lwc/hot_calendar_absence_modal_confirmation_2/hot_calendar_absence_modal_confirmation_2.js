import LightningModal from 'lightning/modal';

export default class Hot_Calendar_Absence_Modal_Confirmation_2 extends LightningModal {
    handleOkay() {
        const isConfirm = true;
        this.close(isConfirm);
    }
    handleDeny() {
        const isConfirm = false;
        this.close(isConfirm);
    }
}
