import { LightningElement, api } from 'lwc';
import icons from '@salesforce/resourceUrl/ikoner';

export default class Hot_welcomebannerV2 extends LightningElement {
    notificationIcon = icons + '/Bell/BellBlue.svg';

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
