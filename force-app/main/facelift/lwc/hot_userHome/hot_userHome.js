import { LightningElement, api } from 'lwc';

export default class Hot_userHome extends LightningElement {
    pageLinks = {};
    @api numberOfUnreadThreads = 0;

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
    get unreadThreadsText() {
        if (!this.numberOfUnreadThreads) {
            return '';
        }
        return this.numberOfUnreadThreads + ' ' + (this.numberOfUnreadThreads === 1 ? 'ulest' : 'uleste');
    }
}
