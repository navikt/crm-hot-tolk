import { LightningElement, api, wire } from 'lwc';
import dispatcherReadComment from '@salesforce/apex/HOT_InterestedResourcesListController.dispatcherReadComment';

export default class Hot_registerDispatcherReadComment extends LightningElement {
	@api recordId;

	connectedCallback() {
		let recordId = this.recordId;
		dispatcherReadComment({ recordId });
	}
}