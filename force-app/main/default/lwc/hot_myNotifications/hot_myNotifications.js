import { LightningElement, track, wire, api } from 'lwc';
import getNotifications from '@salesforce/apex/HOT_UserNotification.getNotifications';

export default class Hot_myNotifications extends LightningElement {
    @wire(getNotifications, { notificationTypeNames: '' })
    handleWire(result) {
        if (result.data) {
            this.notifications = result.data;
            console.log('All notifications ', this.notifications.length);
            console.log('notificatiuon ', JSON.stringify(this.notifications[0]));
        }
    }
    @track notifications = [];
    @api notificationTypes = '';

    @wire(getNotifications, { notificationTypeNames: '$notificationTypes' })
    handlegetNotifications(result) {
        if (result.data) {
            this.res = result.data;
            console.log('only user notifications ', this.res.length);
        }
    }

    varslerPressed = false;
    onHandleClickVarsler() {
        console.log('he');
        this.varslerPressed = !this.varslerPressed;
    }
}
