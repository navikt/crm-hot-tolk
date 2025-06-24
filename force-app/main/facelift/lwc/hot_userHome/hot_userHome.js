import { LightningElement } from 'lwc';

export default class Hot_userHome extends LightningElement {
    pageLinks = {};

    setPageLinks() {
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

    connectedCallback() {
        this.setPageLinks();
    }
}
