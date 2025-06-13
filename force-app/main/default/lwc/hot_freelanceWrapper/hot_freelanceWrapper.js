import { LightningElement } from 'lwc';
import icons from '@salesforce/resourceUrl/ikoner';

export default class Hot_freelanceWrapper extends LightningElement {
    calenderIcon = icons + '/Calender/Calender.svg';
    closeIcon = icons + '/Close/Close.svg';
    warningicon = icons + '/Warning/WarningRed.svg';
    isUserInNorwegianTimeZone = true;
    showCalender = false;
    static STATE_KEY = 'calendarWrapState';

    toggleCalender() {
        this.showCalender = !this.showCalender;
        if (this.showCalender) {
            requestAnimationFrame(() => {
                const calenderEl = this.template.querySelector('[data-id="calenderContent"]');
                if (calenderEl) {
                    calenderEl.scrollIntoView({ behavior: 'smooth' });
                }
            });
        }
    }

    connectedCallback() {
        this.checkTimeZone();
        const state = sessionStorage.getItem(Hot_freelanceWrapper.STATE_KEY);
        if (state != null) {
            const parsedState = JSON.parse(state);
            this.showCalender = parsedState.showCalender;
        }
    }

    disconnectedCallback() {
        const state = {
            showCalender: this.showCalender
        };
        sessionStorage.setItem(Hot_freelanceWrapper.STATE_KEY, JSON.stringify(state));
    }
    checkTimeZone() {
        const osloTime = new Date().toLocaleString('no-NB', { timeZone: 'Europe/Oslo' });
        const userTime = new Date().toLocaleString('no-NB');
        this.isUserInNorwegianTimeZone = osloTime === userTime;
    }
}
