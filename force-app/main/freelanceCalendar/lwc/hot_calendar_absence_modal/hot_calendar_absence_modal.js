import { api } from 'lwc';
import LightningModal from 'lightning/modal';
import ConfimationModal from 'c/hot_calendar_absence_modal_confirmation';
import getConflictsForTimePeriod from '@salesforce/apex/HOT_FreelanceAbsenceController.getConflictsForTimePeriod';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

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
        getConflictsForTimePeriod({
            startTimeInMilliseconds: new Date(absenceStartDateTime).getTime(),
            endTimeInMilliseconds: new Date(absenceEndDateTime).getTime()
        }).then((result) => {
            console.log(result);
        });
        // Do something with the values
        console.log('Selected Radio Value: ', absenceType);
        console.log('Start date/time Value: ', new Date(absenceStartDateTime));
        console.log('End date/time Value: ', absenceEndDateTime);
        const isConfirmation = await ConfimationModal.open();
        if (isConfirmation) {
            this.close('resultat string');
        } else if (!isConfirmation) {
            console.log('not confirmation');
        }
    }
}
