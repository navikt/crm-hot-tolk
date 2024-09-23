import { LightningElement, track } from 'lwc';

export default class Hot_calendar_wrap extends LightningElement {
    @track showCalendar = false;
    @track buttonLabel = 'Oppdragskalender'; // Initial label
    @track iconName = 'utility:event';

    toggleCalendar() {
        this.showCalendar = !this.showCalendar;
        if (this.showCalendar) {
            this.buttonLabel = 'Skjul';
            this.iconName = 'utility:close'; // Icon when the calendar is open
        } else {
            this.buttonLabel = 'Oppdragskalender';
            this.iconName = 'utility:event'; // Icon when the calendar is closed
        }
    }
}
