import { LightningElement, track, wire } from 'lwc';
import icons from '@salesforce/resourceUrl/ikoner';
import getMyNotifications from '@salesforce/apex/HOT_NotificationCentreController.getMyNotifications';

export default class Hot_notificationListViewer extends LightningElement {
    notificationIcon = icons + '/Bell/BellBlue.svg';
    exitCrossIcon = icons + '/Close/Close.svg';
    showNotifications = false;
    @track notifications;

    @wire(getMyNotifications)
    wiredNotifications(result) {
        this.wiredNotificationResult = result;
        if (result.data) {
            const notifications = result.data.map((x) => ({
                ...x,
                created: this.formatDateTime(x.CreatedDate)
            }));

            // Sort by CreatedDate descending
            notifications.sort((a, b) => new Date(b.CreatedDate) - new Date(a.CreatedDate));

            this.notifications = notifications;
            console.log(this.notifications);
        }
    }

    get hasNotifications() {
        return this.notifications && this.notifications.length > 0;
    }
    toggleNotifications() {
        this.showNotifications = !this.showNotifications;
        this.template.querySelector('.dropdown').focus();
    }

    formatDateTime(date) {
        let unformatted = new Date(date);
        let formattedTime =
            ('0' + unformatted.getDate()).slice(-2) +
            '.' +
            ('0' + (unformatted.getMonth() + 1)).slice(-2) +
            '.' +
            unformatted.getFullYear() +
            ', Kl ' +
            ('0' + unformatted.getHours()).slice(-2) +
            ':' +
            ('0' + unformatted.getMinutes()).slice(-2);
        if (formattedTime.includes('NaN')) {
            formattedTime = '';
        }
        return formattedTime;
    }
}
