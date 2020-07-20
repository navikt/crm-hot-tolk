import { LightningElement, wire } from 'lwc';
import getPersonPhoneEmail from '@salesforce/apex/HOT_UserInformationController.getPersonPhoneEmail';

export default class hot_userContactInformation extends LightningElement {
	@wire(getPersonPhoneEmail) person;
}