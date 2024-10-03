import { api } from 'lwc';
import LightningModal from 'lightning/modal';
import ConfimationModal from 'c/hot_calendar_absence_modal_confirmation';

export default class Hot_Calendar_Absence_Modal extends LightningModal {
    @api content;
    value = '';

    get options() {
        return [
            { label: 'Ferie', value: 'Ferie' },
            { label: 'Medisinsk', value: 'Medisisnk' },
            { label: 'Annet', value: 'Annet' }
        ];
    }

    async handleOkay() {
        console.log('trykk');
        // Fetch radio button value
        const radioGroup = this.refs.absenceTypeRadioGroup;
        const absenceType = radioGroup.value;

        // Fetch input field values
        const absenceStartDateTime = this.refs.absenceStartDateTimeInput.value;
        const absenceEndDateTime = this.refs.absenceEndDateTimeInput.value;

        // Do something with the values
        console.log('Selected Radio Value: ', absenceType);
        console.log('Start date/time Value: ', absenceStartDateTime);
        console.log('End date/time Value: ', absenceEndDateTime);
        const isConfirmation = await ConfimationModal.open();
        if (isConfirmation) {
            console.log('confirmation');
            this.close('resultat string');
        } else if (!isConfirmation) {
            console.log('not confirmation');
        }
    }
}
