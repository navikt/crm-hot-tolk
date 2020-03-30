import { LightningElement, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import Id from '@salesforce/user/Id';
import CURRENT_USER from '@salesforce/schema/User.Name';
import IDPORTEN_IKON from '@salesforce/resourceUrl/idporten_ikon';
import LOGO from '@salesforce/resourceUrl/logo';
import SEARCH_BUTTON from '@salesforce/resourceUrl/sok_liten_morkeblaa';
import HAMBURGER_MENY from '@salesforce/resourceUrl/hamburger_meny_ikon';

const fields = [CURRENT_USER];

export default class GlobalHeader extends LightningElement {
	userId = Id;

	@wire(getRecord, { recordId: '$userId', fields })
	user;

	get currentUser() {
		return getFieldValue(this.user.data, CURRENT_USER);
	}
	logo = LOGO;
	idportenIkon = IDPORTEN_IKON;
	searchButton = SEARCH_BUTTON;
	hamburgerMenyIkon = HAMBURGER_MENY;

	toggleMobileMenu() {
		var x = this.template.querySelector(".accessible-megamenu");
		if (x.classList.contains('m-open')) {
			x.classList.remove('m-open');
		} else {
			x.classList.add('m-open');
		}
	}
}