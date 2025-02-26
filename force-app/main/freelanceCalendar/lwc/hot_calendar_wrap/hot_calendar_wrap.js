import { LightningElement, track } from 'lwc';
import icons from '@salesforce/resourceUrl/icons';

export default class Hot_calendar_wrap extends LightningElement {
    @track showCalendar = false;
    @track isUserInNorwegianTimeZone = true;
    @track buttonLabel = 'Kalender'; // Initial label
    static STATE_KEY = 'calendarWrapState';
    warningicon = icons + '/warningicon.svg';

    toggleCalendar() {
        this.showCalendar = !this.showCalendar;
        if (this.showCalendar) {
            this.buttonLabel = 'Skjul';
        } else {
            this.buttonLabel = 'Kalender';
        }
    }

    connectedCallback() {
        this.checkTimeZone();
        const state = sessionStorage.getItem(Hot_calendar_wrap.STATE_KEY);
        if (state != null) {
            const parsedState = JSON.parse(state);
            this.showCalendar = parsedState.showCalendar;
            this.buttonLabel = this.showCalendar ? 'Skjul' : 'Kalender';
        }
    }

    disconnectedCallback() {
        const state = {
            showCalendar: this.showCalendar
        };
        sessionStorage.setItem(Hot_calendar_wrap.STATE_KEY, JSON.stringify(state));
    }
    checkTimeZone() {
        const osloTime = new Date().toLocaleString('no-NB', { timeZone: 'Europe/Oslo' });
        const userTime = new Date().toLocaleString('no-NB');
        this.isUserInNorwegianTimeZone = osloTime === userTime;
    }
}
