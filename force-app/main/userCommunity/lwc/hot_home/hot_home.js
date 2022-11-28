import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import HOT_HOME_LOGOS from '@salesforce/resourceUrl/hot_home_logos';

export default class Hot_home extends NavigationMixin(LightningElement) {
    mineSamtalerImg = HOT_HOME_LOGOS + '/MineSamtaler.svg';
    mineBestillingerImg = HOT_HOME_LOGOS + '/MineBestillinger.svg';
    minSideImg = HOT_HOME_LOGOS + '/MinSide.svg';
    minTidsplanImg = HOT_HOME_LOGOS + '/MinTidsplan.svg';
    kunnskapsbankenImg = HOT_HOME_LOGOS + '/Kunnskapsbanken.svg';
    bestilleTolkImg = HOT_HOME_LOGOS + '/BestilleTolk.svg';

    @track pageLinks = {};
    connectedCallback() {
        sessionStorage.clear(); // Clear session storage when on home
        window.scrollTo(0, 0);
        let baseURLArray = window.location.pathname.split('/');
        baseURLArray.pop();
        let baseURL = baseURLArray.join('/');
        this.pageLinks = {
            newRequest: baseURL + '/ny-bestilling',
            myRequests: baseURL + '/mine-bestillinger',
            myRequestsOther: baseURL + '/mine-bestillinger-andre',
            myPage: baseURL + '/min-side',
            myThreads: baseURL + '/mine-samtaler'
        };
    }
}
