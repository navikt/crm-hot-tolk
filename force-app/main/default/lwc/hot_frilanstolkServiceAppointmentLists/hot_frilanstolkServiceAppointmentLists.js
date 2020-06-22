import { LightningElement, wire, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';


export default class Hot_frilanstolkServiceAppointmentLists extends NavigationMixin(LightningElement) {


	onOpen() {
		console.log("ledige");
		const columnLabels = ["'Oppdragsnummer'", "''", "'Tid'", "'Adresse'", "'Arbeidstype'", "'Påmeldte'", "'Frist"];
		for (var i = 0; i < columnLabels.length; i++) {
			document.documentElement.style.setProperty('--columnlabel_' + i.toString(), columnLabels[i]);
		}
	}
	onInterested() {
		console.log("interested");
		const columnLabels = ["'Oppdragsnummer'", "''", "'Tid'", "'Adresse'", "'Status'", "'Ny kommentar'", "''"];
		for (var i = 0; i < columnLabels.length; i++) {
			document.documentElement.style.setProperty('--columnlabel_' + i.toString(), columnLabels[i]);
		}
	}
	onMy() {
		console.log("mine");
		const columnLabels = ["'Oppdragsnummer'", "'Tid'", "'Adresse'", "'Status'", "''", "''", "''"];
		for (var i = 0; i < columnLabels.length; i++) {
			document.documentElement.style.setProperty('--columnlabel_' + i.toString(), columnLabels[i]);
		}
	}


	goToHome(event) {
		if (!this.isProd) {
			event.preventDefault();
			this[NavigationMixin.Navigate]({
				type: 'comm__namedPage',
				attributes: {
					pageName: 'home'
				},
			});
		}
	}





}

