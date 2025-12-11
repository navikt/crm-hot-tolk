import { LightningElement, api } from 'lwc';

export default class Hot_welcomebannerV2 extends LightningElement {
    showNotificationList = false;

    @api personDetails;
    @api announcements;

    get isMobilePublisher() {
        const ua = navigator.userAgent;
        return ua.includes('SalesforceMobile') || ua.includes('Salesforce1');
    }

    get isNotMobilePublisher() {
        return !this.isMobilePublisher;
    }

    get personFirstName() {
        if (!this.personDetails || !this.personDetails.FirstName) {
            return '';
        }

        return this.personDetails.FirstName.split(' ')
            .map((word) => word.charAt(0).toUpperCase() + word.slice(1).toLowerCase())
            .join(' ');
    }
}
