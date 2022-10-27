import { LightningElement, wire, track } from 'lwc';
import getPersonPhoneEmail from '@salesforce/apex/HOT_UserInformationController.getPersonPhoneEmail';
import { NavigationMixin } from 'lightning/navigation';

export default class hot_userContactInformation extends NavigationMixin(LightningElement) {
    @track person;
    @track recordId;
    @wire(getPersonPhoneEmail)
    wiredPerson(result) {
        if (result.data) {
            this.person = result.data;
            this.recordId = this.person.Id;
        }
    }

    goBack() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                pageName: 'home'
            }
        });
    }
}
