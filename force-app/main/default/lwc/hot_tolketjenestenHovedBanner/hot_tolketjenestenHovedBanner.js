import { LightningElement, track } from 'lwc';


export default class Hot_tolketjenestenHovedBanner extends LightningElement {
	@track isProd = window.location.toString().includes("tolkebestilling.nav.no/");


}