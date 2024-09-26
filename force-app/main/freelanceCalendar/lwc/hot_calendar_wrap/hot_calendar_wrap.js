import { LightningElement, track } from 'lwc';

export default class Hot_calendar_wrap extends LightningElement {
    @track showCalendar = false;
    @track buttonLabel = 'Kalender'; // Initial label

    toggleCalendar() {
        this.showCalendar = !this.showCalendar;
        if (this.showCalendar) {
            this.buttonLabel = 'Skjul';
        } else {
            this.buttonLabel = 'Kalender';
        }
    }
}
