import { LightningElement, track } from 'lwc';

export default class Hot_calendar_wrap extends LightningElement {
    @track showCalendar = false;
    @track buttonLabel = 'Kalender'; // Initial label
    static STATE_KEY = 'calendarWrapState';

    toggleCalendar() {
        this.showCalendar = !this.showCalendar;
        if (this.showCalendar) {
            this.buttonLabel = 'Skjul';
        } else {
            this.buttonLabel = 'Kalender';
        }
    }

    connectedCallback() {
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
}
