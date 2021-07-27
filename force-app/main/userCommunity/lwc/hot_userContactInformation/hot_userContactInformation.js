import { LightningElement, wire, track } from 'lwc';
import getPersonPhoneEmail from '@salesforce/apex/HOT_UserInformationController.getPersonPhoneEmail';
import isProdFunction from '@salesforce/apex/GlobalCommunityHeaderFooterController.isProd';

export default class hot_userContactInformation extends LightningElement {
    @track person;
    @track recordId;
    @wire(getPersonPhoneEmail)
    wiredPerson(result) {
        if (result.data) {
            this.person = result.data;
            this.recordId = this.person.Id;
        }
    }
    @track isProd;
    @track error;
    @wire(isProdFunction)
    wiredIsProd({ error, data }) {
        this.isProd = data;
    }
}
