import { LightningElement, track } from 'lwc';
export default class Hot_notificationCentreLink extends LightningElement {
    @track pageLinks = {};
    connectedCallback() {
        let baseURLArray = window.location.pathname.split('/');
        baseURLArray.pop();
        let baseURL = baseURLArray.join('/');
        this.pageLinks = {
            myNotifications: baseURL + '/mine-varsler'
        };
    }
}
