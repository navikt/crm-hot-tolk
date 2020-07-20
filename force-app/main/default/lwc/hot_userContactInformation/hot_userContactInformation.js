import { LightningElement, wire } from 'lwc';
import getPerson from '@salesforce/apex/HOT_UserContactInformationController.getPerson';

export default class hot_userContactInformation extends LightningElement {
	@wire(getPerson) person;
}