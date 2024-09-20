import { LightningElement } from 'lwc';

export default class Hot_calendar_wrap extends LightningElement {
    showCalendar = false;
    toggleCalendar() {
        this.showCalendar = !this.showCalendar;
    }
}
