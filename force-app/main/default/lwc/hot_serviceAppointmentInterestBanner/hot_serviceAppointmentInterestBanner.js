import { LightningElement, api, wire } from 'lwc';
import hasRegisteredInterest from '@salesforce/apex/HOT_InterestedResourceBannerController.hasRegisteredInterest';

export default class Hot_serviceAppointmentInterestBanner extends LightningElement {
    @api recordId;

    @wire(hasRegisteredInterest, { serviceAppointmentId: '$recordId' })
    interestState;

    get showBanner() {
        return this.interestState?.data === true;
    }
}
