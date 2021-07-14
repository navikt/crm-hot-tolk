import { LightningElement, track, wire } from 'lwc';
import getServiceResource from '@salesforce/apex/HOT_FreelanceUserInformationController.getServiceResource';

export default class Hot_frilanstolkEditProfile extends LightningElement {
    @track serviceResource;
    @track recordId;
    @wire(getServiceResource)
    wiredGetServiceResource(result) {
        if (result.data) {
            this.serviceResource = result.data;
            this.recordId = this.serviceResource.Id;
        }
    }
    // dummy function to test buttons
    updateProfile() {
        alert('Profil er oppdatert!');
    }
}
