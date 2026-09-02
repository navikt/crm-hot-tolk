import { LightningElement, api } from 'lwc';
import icons from '@salesforce/resourceUrl/ikoner';

export default class Hot_freelanceWrapper extends LightningElement {
    @api numberOfUnreadThreads = 0;
    pageLinks = {};
    calenderIcon = icons + '/Calender/Calender.svg';
    closeIcon = icons + '/Close/Close.svg';
    warningIcon = icons + '/Warning/WarningRed.svg';

    isUserInNorwegianTimeZone = true;
    showCalender = false;

    pageLinks = {};

    static STATE_KEY = 'calendarWrapState';

    toggleCalender() {
        this.showCalender = !this.showCalender;
    }

    setPageLinks() {
        let baseURLArray = window.location.pathname.split('/');
        baseURLArray.pop();
        let baseURL = baseURLArray.join('/');
        this.pageLinks = {
            freelanceMyServiceAppointments: baseURL + '/mine-oppdrag',
            freelanceMyUserInformation: baseURL + '/frilanstolk-min-side',
            freelanceMyThreads: baseURL + '/mine-samtaler-frilanstolk'
        };
    }

    checkTimeZone() {
        const osloTime = new Date().toLocaleString('no-NB', { timeZone: 'Europe/Oslo' });
        const userTime = new Date().toLocaleString('no-NB');
        this.isUserInNorwegianTimeZone = osloTime === userTime;
    }

    connectedCallback() {
        sessionStorage.clear(); // Clear session storage when on home
        window.scrollTo(0, 0);
        let baseURLArray = window.location.pathname.split('/');
        baseURLArray.pop();
        let baseURL = baseURLArray.join('/');
        this.pageLinks = {
            myServiceAppointments: baseURL + '/mine-oppdrag',
            freelanceMyPage: baseURL + '/frilanstolk-min-side',
            freelanceMyThreads: baseURL + '/mine-samtaler-frilanstolk'
        };
        this.checkTimeZone();
        this.setPageLinks();
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
    get unreadThreadsText() {
        if (!this.numberOfUnreadThreads) {
            return '';
        }
        return this.numberOfUnreadThreads + ' ' + (this.numberOfUnreadThreads === 1 ? 'ulest' : 'uleste');
    }
}