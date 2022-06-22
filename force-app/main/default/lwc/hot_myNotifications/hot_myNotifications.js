import { LightningElement, track, wire } from 'lwc';
import getNotifications from '@salesforce/apex/HOT_UserNotification.getNotifications';

export default class Hot_myNotifications extends LightningElement {
    @wire(getNotifications)
    handleWire(result) {
        console.log(result);
        if (result.data) {
            this.getParse(result.data).then((res) => {
                this.notifications = res.notifications;
                console.log(this.notifications);
            });
            console.log(this.notifications);
        }
    }
    @track notifications = [];

    getParse(input) {
        return JSON.parse(input);
    }
}
