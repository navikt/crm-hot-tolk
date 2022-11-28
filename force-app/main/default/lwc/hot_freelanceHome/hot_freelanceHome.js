import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class Hot_freelanceHome extends NavigationMixin(LightningElement) {
    @track pageLinks = {};
    connectedCallback() {
        sessionStorage.clear(); // Clear session storage when on home
        window.scrollTo(0, 0);
        let baseURLArray = window.location.pathname.split('/');
        baseURLArray.pop();
        let baseURL = baseURLArray.join('/');
        this.pageLinks = {
            myServiceAppointments: baseURL + '/mine-oppdrag',
            freelanceMyPage: baseURL + '/frilanstolk-min-side'
        };
    }
}
