import { LightningElement, wire, track } from 'lwc';
import getUserInformation from '@salesforce/apex/HOT_UserInformationController.getUserInformation';

export default class Hot_homeWrapper extends LightningElement {
    personDetails;
    isFreelance = false;

    @wire(getUserInformation, {})
    wireuser({ data }) {
        if (data) {
            this.personDetails = {
                FirstName: data.FirstName,
                ProfileName: data.Profile.Name
            };
            this.isFreelance = data.Profile.Name === 'NAV Samhandler';
        }
    }
}
