import { LightningElement, track, wire, api } from 'lwc';
import getNotifications from '@salesforce/apex/HOT_UserNotification.getNotifications';

export default class Hot_myNotifications extends LightningElement {
    @track notificationClass = {};
    @track notifications = [];
    @api notificationTypes = '';

    @wire(getNotifications, { notificationTypeNames: '$notificationTypes' })
    handlegetNotifications(result) {
        console.log(result);
        console.log(JSON.stringify(result));
        if (result.data) {
            this.notificationClass = result.data;
            this.notifications = result.data.notifications;
        }
    }

    varslerPressed = false;
    onHandleClickVarsler() {
        console.log('he');
        this.varslerPressed = !this.varslerPressed;
    }
}
