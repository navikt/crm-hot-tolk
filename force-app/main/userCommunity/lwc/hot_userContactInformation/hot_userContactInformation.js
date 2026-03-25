import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getPersonPhoneEmailAndStatus from '@salesforce/apex/HOT_UserInformationController.getPersonPhoneEmailAndStatus';
import updateKrrStatus from '@salesforce/apex/HOT_UserInformationController.updateKrrStatus';
import icons from '@salesforce/resourceUrl/icons';

export default class hot_userContactInformation extends NavigationMixin(LightningElement) {
    informationIcon = icons + '/informationicon.svg';
    @track person;
    @track recordId;
    @wire(getPersonPhoneEmailAndStatus)
    wiredPerson(result) {
        this.wiredPersonResult = result;
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
    get alternativePhoneNumberText() {
        return 'Du har registrert et alternativ nummer som benyttes til all SMS varsling fra Tolketjenesten. Ta kontakt med din lokale tolketjeneste om du ønsker å endre dette.';
    }
    get isAlternativeNumber() {
        if (this.person != null && this.person.HOT_MobilePhoneOverride__c != null) {
            return true;
        } else {
            return false;
        }
    }
    setKrrIntegrationStatusToQueued() {
        var personCloned = JSON.parse(JSON.stringify(this.person));
        try {
            personCloned.INT_KrrIntegrationStatus__c = 'Queued';
            updateKrrStatus({ receivedPerson: personCloned });
        } catch (error) {
            console.log(error);
        }
    }

    get isKrrQueued() {
        return this.person?.INT_KrrIntegrationStatus__c == 'Queued';
    }
}
