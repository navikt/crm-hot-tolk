import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class Hot_home extends NavigationMixin(LightningElement) {

	goToMyRequests() {
		this[NavigationMixin.Navigate]({
			type: 'comm__namedPage',
			attributes: {
				pageName: 'mine-bestillinger'
			}
		});
	}

	goToNewRequest() {
		this[NavigationMixin.Navigate]({
			type: 'comm__namedPage',
			attributes: {
				pageName: 'ny-bestilling'
			},
		});
	}

	goToKnowledgebank() {
		this[NavigationMixin.Navigate]({
			type: 'standard__webPage',
			attributes: {
				url: 'https://www.kunnskapsbanken.net/om-kommunikasjon-sprak-og-tolking/'
			},
		});
	}

}