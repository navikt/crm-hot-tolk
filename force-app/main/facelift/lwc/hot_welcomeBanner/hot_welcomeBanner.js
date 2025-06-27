import { LightningElement, api } from 'lwc';

export default class Hot_welcomebannerV2 extends LightningElement {
    showNotificationList = false;

    @api personDetails;

    get personFirstName() {
        if (!this.personDetails || !this.personDetails.FirstName) {
            return '';
        }

        return this.personDetails.FirstName.split(' ')
            .map((word) => word.charAt(0).toUpperCase() + word.slice(1).toLowerCase())
            .join(' ');
    }
}
