import { LightningElement, track, wire, api } from 'lwc';
import getNotifications from '@salesforce/apex/HOT_UserNotification.getNotifications';
import dekoratoren from '@salesforce/resourceUrl/dekoratoren';
import { loadStyle } from 'lightning/platformResourceLoader';

export default class Hot_myNotifications extends LightningElement {
    @wire(getNotifications, { notificationTypeNames: '' })
    handleWire(result) {
        if (result.data) {
            this.notifications = result.data;
            console.log('All notifications ', this.notifications.length);
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
        this.varslerPressed = !this.varslerPressed;
    }
}
