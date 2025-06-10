import { LightningElement, track } from 'lwc';
import icons from '@salesforce/resourceUrl/ikoner';

export default class Hot_notificationListViewer extends LightningElement {
    notificationIcon = icons + '/Bell/BellBlue.svg';
    showNotifications = false;
    notifications = [
        {
            id: 1,
            title: 'SA-481484 - 21.5.2025 10:30 - endret adresse',
            description: 'Ny adresse er Skolegata 14, Tromsø',
            date: '13.05.2025, kl 10:97 Push-varsel i appen'
        },
        {
            id: 2,
            title: 'Du er tildelt oppdraget SA-343434',
            description: 'Tidspunkt for oppdraget er 23.07.2025 kl 15.00-16.00',
            date: '11.05.2025, kl 10:79 Push-varsel i appen'
        }
        // Add the other notifications here...
        //SKIR VIER JERIO FJDPOFÅL
    ];

    get hasNotifications() {
        return this.notifications && this.notifications.length > 0;
    }
    toggleNotifications() {
        this.showNotifications = !this.showNotifications;
        this.template.querySelector('.dropdown').focus();
    }
}
