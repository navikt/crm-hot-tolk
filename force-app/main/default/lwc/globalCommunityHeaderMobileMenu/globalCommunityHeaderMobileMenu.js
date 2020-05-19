import { LightningElement, track, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { fireEvent } from 'c/pubsub';
import ID from '@salesforce/user/Id';
import CURRENT_USER from '@salesforce/schema/User.Name';

const fields = [CURRENT_USER];

const screenWidth = screen.width;
const headerHeight = screenWidth > 576 ? 91 : 88;
const headerStartPosition = screenWidth > 576 ? 44 : 0;
var headerPosition = headerStartPosition;
var hovedbannerposition = headerStartPosition + headerHeight;
document.documentElement.style.setProperty('--hovedbannerposition', hovedbannerposition.toString() + "px");
document.documentElement.style.setProperty('--headerPosition', headerPosition.toString() + "px");
var prevScrolled = 0;


window.addEventListener('scroll', () => {
	var scrolled = window.scrollY;
	const difference = scrolled - prevScrolled;
	if (difference >= 0) {
		if (headerPosition > -headerHeight) {
			headerPosition = headerPosition - difference;
			hovedbannerposition = headerPosition + headerHeight;
		}
		else {
			headerPosition = -headerHeight
			hovedbannerposition = 0;
		}
	}
	else {
		if (headerPosition < 0) {
			headerPosition = headerPosition - difference;
			hovedbannerposition = headerPosition + headerHeight;
		}
		else if (scrolled < headerStartPosition) {
			headerPosition = headerStartPosition - scrolled;
			hovedbannerposition = headerPosition + headerHeight;
		}
		else {
			headerPosition = 0;
			hovedbannerposition = headerHeight;
		}

	}
	document.documentElement.style.setProperty('--headerPosition', headerPosition.toString() + "px");
	document.documentElement.style.setProperty('--hovedbannerposition', hovedbannerposition.toString() + "px");

	prevScrolled = scrolled;

});

export default class GlobalCommunityHeaderMobileMenu extends LightningElement {


	userId = ID;
	@wire(getRecord, { recordId: '$userId', fields })
	user;
	get currentUser() {
		return getFieldValue(this.user.data, CURRENT_USER);
	}


	handleOnScroll() {
	}


	@track searchPressed = false;
	handleOnClickSearch(event) {
		this.searchPressed = !this.searchPressed;
	}
	@track varslerPressed = false;
	onHandleClickVarsler() {
		this.varslerPressed = !this.varslerPressed;
	}
	@track minSidePressed = false;
	handleOnClickMinSide() {
		this.minSidePressed = !this.minSidePressed;
	}


	@track menuPressed = false;
	handleOnClickMenu(event) {
		console.log("meny");
		this.menuPressed = !this.menuPressed;
		this.isPrivatPerson = !this.isPrivatPerson;
		this.sendMenuSelectedEvent();
	}
	@track isUnderMeny1 = false;
	@track isUnderMeny2 = false;
	@track isUnderMeny3 = false;
	@track isUnderMeny4 = false;
	@track isUnderMeny5 = false;
	@track isUnderMeny6 = false;
	@track isUnderMeny7 = false;
	@track isUnderMeny8 = false;
	onHandleBackToMenu() {
		this.isUnderMeny1 = false;
		this.isUnderMeny2 = false;
		this.isUnderMeny3 = false;
		this.isUnderMeny4 = false;
		this.isUnderMeny5 = false;
		this.isUnderMeny6 = false;
		this.isUnderMeny7 = false;
		this.isUnderMeny8 = false;
	}
	onHandleUnderMeny1() {
		this.isUnderMeny1 = true;
	}
	onHandleUnderMeny2() {
		this.isUnderMeny2 = true;
	}
	onHandleUnderMeny3() {
		this.isUnderMeny3 = true;
	}
	onHandleUnderMeny4() {
		this.isUnderMeny4 = true;
	}
	onHandleUnderMeny5() {
		this.isUnderMeny5 = true;
	}
	onHandleUnderMeny6() {
		this.isUnderMeny6 = true;
	}
	onHandleUnderMeny7() {
		this.isUnderMeny7 = true;
	}
	onHandleUnderMeny8() {
		this.isUnderMeny8 = true;
	}


	@track isPrivatPerson = false;
	@track isArbeidsgiver = false;
	@track isSamarbeidspartner = false;
	handleOnClickPrivatPerson(event) {
		this.isPrivatPerson = true;
		this.isArbeidsgiver = false;
		this.isSamarbeidspartner = false;
		this.sendClientTypeSelectedEvent();
	}
	handleOnClickArbeidsgiver(event) {
		this.isPrivatPerson = false;
		this.isArbeidsgiver = true;
		this.isSamarbeidspartner = false;
		this.sendClientTypeSelectedEvent();
	}
	handleOnClickSamarbeidspartner(event) {
		this.isPrivatPerson = false;
		this.isArbeidsgiver = false;
		this.isSamarbeidspartner = true;
		this.sendClientTypeSelectedEvent();
	}

	@wire(CurrentPageReference) pageRef;
	sendClientTypeSelectedEvent() {
		var data = {
			isPrivatPerson: this.isPrivatPerson,
			isArbeidsgiver: this.isArbeidsgiver,
			isSamarbeidspartner: this.isSamarbeidspartner,
		}
		fireEvent(this.pageRef, 'clienttypeselected', data);
	}
	sendMenuSelectedEvent() {
		fireEvent(this.pageRef, 'menuSelectedEvent', this.menuPressed);
	}



}
