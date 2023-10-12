import { LightningElement, track } from 'lwc';
import ICON_Bell from '@salesforce/resourceUrl/Bell';
export default class Hot_notificationCentreLink extends LightningElement {
    bellIcon = ICON_Bell;
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
