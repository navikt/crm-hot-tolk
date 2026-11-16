import { LightningElement, api } from 'lwc';
import TOLK_CHRISTMASLOGO from '@salesforce/resourceUrl/tolketjenestenJulLogo';

export default class Hot_welcomebannerV2 extends LightningElement {
    showNotificationList = false;
    logoUrl = TOLK_CHRISTMASLOGO;

    @api personDetails;
    @api announcements;
    @api unreadAnnouncementIds;

    get isChristmasSeason() {
        const today = new Date();
        const month = today.getMonth();
        const day = today.getDate();

        return (month === 10 && day === 30) || month === 11 || (month === 0 && day <= 2);
    }

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
