import { LightningElement, wire, track } from 'lwc';
import getPerson from '@salesforce/apex/HOT_UserInformationController.getPerson'

export default class hot_tolketjenestenUserInformation extends LightningElement {
	@track person;
	@track recordId;
	@wire(getPerson)
	wiredGetPerson(result) {
		if (result.data) {
			this.person = result.data;
			this.recordId = this.person.Id;
		}
		console.log('wiredGetPerson');
		console.log(JSON.stringify(this.person));
	}
}