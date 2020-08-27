import { LightningElement, wire, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getRequestList from '@salesforce/apex/HOT_RequestListContoller.getRequestList';
import isProdFunction from '@salesforce/apex/GlobalCommunityHeaderFooterController.isProd';
import getPersonAccount from '@salesforce/apex/HOT_Utility.getPersonAccount';
import getOrdererDetails from '@salesforce/apex/HOT_Utility.getOrdererDetails';

export default class RecordFormCreateExample extends NavigationMixin(LightningElement) {
	@track reRender = 0;

	@track isProd;
	@track error;
	@wire(isProdFunction)
	wiredIsProd({ error, data }) {
		this.isProd = data;
	}


	@track submitted = false; // if:false={submitted}
	acceptedFormat = '[.pdf, .png, .doc, .docx, .xls, .xlsx, .ppt, pptx, .txt, .rtf]';

	@track recordId = null;
	@track allRequests;
	@track requests;
	@track error;
	wiredRequestsResult;

	@wire(getRequestList)
	wiredRequest(result) {
		this.wiredRequestsResult = result;
		if (result.data) {
			this.allRequests = result.data;
			this.filterRequests();
			this.error = undefined;
		} else if (result.error) {
			this.error = result.error;
			this.requests = undefined;
		}
	}
	filterRequests() {
		var tempRequests = [];
		for (var i = 0; i < this.allRequests.length; i++) {
			if (this.allRequests[i].ExternalRequestStatus__c != "Avlyst" &&
				this.allRequests[i].ExternalRequestStatus__c != "Dekket" &&
				this.allRequests[i].ExternalRequestStatus__c != "Udekket") {
				tempRequests.push(this.allRequests[i]);
			}
		}
		this.requests = tempRequests;
	}

	isDuplicate(fields) {
		var isDuplicate = null;
		for (var i = 0; i < this.requests.length; i++) {
			if ((this.requests[i].StartTime__c <= fields.StartTime__c && fields.StartTime__c <= this.requests[i].EndTime__c
				||
				fields.StartTime__c <= this.requests[i].StartTime__c && this.requests[i].StartTime__c <= fields.EndTime__c)
				&&
				this.requests[i].Id != this.recordId) {
				isDuplicate = i;
				break;
			}
		}
		return isDuplicate;
	}

	@track sameLocation = true;
	value = 'yes';
	get options() {
		return [
			{ label: 'Ja', value: 'yes' },
			{ label: 'Nei', value: 'no' },
		];
	}
	@track personAccount = { Id: "", Name: "" };
	@track ordererDetails = { OrdererEmail__c: "", OrdererPhone__c: "" };

	@wire(getPersonAccount)
	wiredGetPersonAccount(result) {
		if (result.data) {
			this.personAccount = result.data;
		}
	}
	@wire(getOrdererDetails)
	wiredGetOrdererDetails(result) {
		if (result.data) {
			this.ordererDetails = result.data;
			console.log(JSON.stringify(this.ordererDetails));
		}
	}

	@track ordererForm = false;
	@track userForm = false;
	@track companyForm = false;
	@track requestForm = false;
	@track publicEventForm = false;

	@track currentRequestType = "";
	get requestTypes() {
		return [
			{ label: 'Bestille for meg selv', value: 'me' },
			{ label: 'Bestille for bruker', value: 'user' },
			{ label: 'Bestille for bruker, virksomheten betaler', value: 'user_company' },
			{ label: 'Bestille til arrangement, virksomheten betaler', value: 'company' }
		];
	}

	@track showNextButton = true;

	handleRequestTypeChange(event) {
		this.currentRequestType = event.detail.value;
		this.fieldValues.Source__c = "Annen Bestiller";
		console.log(JSON.stringify(this.personAccount));
		console.log(JSON.stringify(this.ordererDetails));
	}

	get getEventTypes() {
		return [
			{ label: 'Idrettsarrangement', value: 'sporting_event' },
			{ label: 'Annet', value: 'other_event' },
		];
	}
	@track eventType = null;
	handleChoiceOfEvent(event) {
		console.log(event.detail.value);
		this.eventType = event.detail.value;
	}


	@track error;
	@track fieldValues = {
		Name: "", Subject__c: "", StartTime__c: "", EndTime__c: "", MeetingStreet__c: "", MeetingPostalCity__c: "", MeetingPostalCode__c: "", Description__C: "",
		IsOtherEconomicProvicer__c: false, OrganizationNumber__c: "", InvoiceReference__c: "", AdditionalInvoiceText__c: "",
		UserName__c: "", UserPersonNumber__c: "", Orderer__c: "",
		OrdererEmail__c: "", OrdererPhone__c: "",
		//Source__c: "Bruker",
	};

	checkPersonNumber(event) {
		console.log("checkPersonNumber")
		var inputComponent = this.template.querySelector(".skjema").querySelector(".personNumber");

		let regExp = RegExp("[0-7][0-9][0-1][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]");
		if (!regExp.test(inputComponent.value)) {
			console.log("invalid")
			inputComponent.setCustomValidity("Fødselsnummeret er ikke gyldig");
			inputComponent.focus();
		} else {
			console.log("valid")
			inputComponent.setCustomValidity("");
			this.fieldValues.UserPersonNumber__c = inputComponent.value;
		}
		inputComponent.reportValidity();

	}


	@track startTime;
	@track endTime;
	handleChange(event) {
		var now = new Date();
		var tempTime = event.detail.value;
		tempTime = tempTime.split("");

		if (this.startTime == null) {
			if (Math.abs(parseFloat(tempTime[14] + tempTime[15]) - now.getMinutes()) <= 1) {
				tempTime[14] = '0';
				tempTime[15] = '0';
			}
			this.startTime = tempTime.join("");
			var first = parseFloat(tempTime[11]);
			var second = parseFloat(tempTime[12]);
			second = (second + 1) % 10;
			if (second == 0) {
				first = first + 1;
			}
			tempTime[11] = first.toString();
			tempTime[12] = second.toString();
			this.endTime = tempTime.join("");
		}
		else {
			this.startTime = event.detail.value;
		}
		if (event.detail.value > this.endTime) {
			var first = parseFloat(tempTime[11]);
			var second = parseFloat(tempTime[12]);
			second = (second + 1) % 10;
			if (second == 0) {
				first = first + 1;
			}
			tempTime[11] = first.toString();
			tempTime[12] = second.toString();
			this.endTime = tempTime.join("");
		}
	}
	setEndTime(event) {
		this.endTime = event.detail.value;
	}

	@track spin = false;

	handleSubmit(event) {
		console.log("handleSubmit");
		this.spin = true;
		event.preventDefault();
		const fields = event.detail.fields;

		this.fieldValues.OrdererEmail__c = fields.OrdererEmail__c;
		this.fieldValues.OrdererPhone__c = fields.OrdererPhone__c;

		this.fieldValues.Orderer__c = this.personAccount.Id;
		for (const k in fields) {
			this.fieldValues[k] = fields[k];
		}
		if (this.sameLocation) {
			this.fieldValues.InterpretationStreet__c = fields.MeetingStreet__c;
			this.fieldValues.InterpretationPostalCode__c = fields.MeetingPostalCode__c;
			this.fieldValues.InterpretationPostalCity__c = fields.MeetingPostalCity__c;
		}

		if (fields) {
			let typeOfEventElement = this.template.querySelector(".skjema").querySelector(".type-arrangement");
			typeOfEventElement.setCustomValidity("");
			console.log(this.eventType);
			if (this.eventType == null && this.publicEventForm) {

				typeOfEventElement.setCustomValidity("Du må velge type arrangement");
				typeOfEventElement.focus();
				this.spin = false;
			}
			else {

				const isDuplicate = this.isDuplicate(this.fieldValues);
				if (isDuplicate == null) {
					console.log("Sumbitting")
					this.template.querySelector('.skjema').querySelector('lightning-record-edit-form').submit(this.fieldValues);
					console.log("submitted");
				}

				else {
					if (confirm("Du har allerede en bestilling på samme tidspunkt\nTema: " + this.requests[isDuplicate].Subject__c +
						"\nFra: " + this.formatDateTime(this.requests[isDuplicate].StartTime__c) +
						"\nTil: " + this.formatDateTime(this.requests[isDuplicate].EndTime__c)
						+ "\n\nFortsett?")) {
						this.template.querySelector('lightning-record-edit-form').submit(this.fieldValues);
					}
					else {
						this.spin = false;
					}

				}
			}
			typeOfEventElement.reportValidity();
		}
	}

	onHandleNeste() {
		console.log("onHandleNeste")
		let radioButtonGroup = this.template.querySelector(".skjema").querySelector(".requestTypeChoice");
		//Pressed "NESTE"
		if (this.currentRequestType != "") {
			this.spin = false;

			if (this.currentRequestType == 'user') {
				this.ordererForm = true;
				this.userForm = true;
			}
			else if (this.currentRequestType == 'user_company') {
				this.ordererForm = true;
				this.userForm = true;
				this.companyForm = true;
				this.fieldValues.IsOtherEconomicProvicer__c = true;
			}
			else if (this.currentRequestType == 'company') {
				this.publicEventForm = true;
				this.ordererForm = true;
				this.companyForm = true;
				this.fieldValues.IsOtherEconomicProvicer__c = true;
			}
			this.requestForm = true;
			this.showNextButton = false;
			radioButtonGroup.setCustomValidity("");
		}
		else {

			radioButtonGroup.setCustomValidity("Du må velge type bestilling");
		}
		radioButtonGroup.reportValidity();
	}

	formatDateTime(dateTime) {
		const year = dateTime.substring(0, 4);
		const month = dateTime.substring(5, 7);
		const day = dateTime.substring(8, 10);

		var time = dateTime.substring(11, 16).split("");
		time[1] = ((parseFloat(time[1]) + 2) % 10).toString();
		time[0] = (parseFloat(time[0]) + ((parseFloat(time[1]) + 2) > 9) ? 1 : 0).toString();
		time = time.join("");
		return day + "." + month + "." + year + " " + time;
	}

	handleError(event) {
		console.log("handleError");
		this.spin = false;
	}

	handleSuccess(event) {
		this.spin = false;
		console.log("handleSuccess");
		var x = this.template.querySelector(".submitted-true");
		x.classList.remove('hidden');
		this.template.querySelector(".h2-successMessage").focus();
		x = this.template.querySelector(".submitted-false");
		x.classList.add('hidden');
		this.recordId = event.detail.id;
		window.scrollTo(0, 0);
	}

	handleUploadFinished(event) {
		// Get the list of uploaded files
		const uploadedFiles = event.detail.files;
		alert(uploadedFiles.length + " filer ble lastet opp.");
	}

	toggled() {
		this.sameLocation = !this.sameLocation;
	}


	previousPage = 'home';

	connectedCallback() {
		console.log("connectedCallback");
		//this.personAccount.Name = "rolf";
		let testURL = window.location.href;
		let params = testURL.split("?")[1];

		function parse_query_string(query) {
			var vars = query.split("&");
			var query_string = {};
			for (var i = 0; i < vars.length; i++) {
				var pair = vars[i].split("=");
				var key = decodeURIComponent(pair[0]);
				var value = decodeURIComponent(pair[1]);
				// If first entry with this name
				if (typeof query_string[key] === "undefined") {
					query_string[key] = decodeURIComponent(value);
					// If second entry with this name
				} else if (typeof query_string[key] === "string") {
					var arr = [query_string[key], decodeURIComponent(value)];
					query_string[key] = arr;
					// If third or later entry with this name
				} else {
					query_string[key].push(decodeURIComponent(value));
				}
			}
			return query_string;
		}

		if (params != undefined) {
			var parsed_params = parse_query_string(params);

			if (parsed_params.fromList != null) {
				this.previousPage = 'mine-bestillinger';
			}

			if (parsed_params.fieldValues != null) {

				this.fieldValues = JSON.parse(parsed_params.fieldValues);
				this.sameLocation = this.fieldValues.MeetingStreet__c == this.fieldValues.InterpretationStreet__c;
				if (!this.sameLocation) {
					this.value = 'no';
				}

				this.recordId = this.fieldValues.Id;

				this.showNextButton = !(parsed_params.edit != null || parsed_params.copy != null);
				if (!this.showNextButton) {
					this.requestForm = true;
					this.ordererForm = true;
					this.userForm = parsed_params.fieldValues.UserPersonNumber__c != null;
					this.companyForm = parsed_params.fieldValues.OrganizationNumber__c != null;

				}
			}
		}

	}



	//Navigation functions
	goToNewRequest(event) {
		if (!this.isProd) {
			event.preventDefault();
			this[NavigationMixin.Navigate]({
				type: 'comm__namedPage',
				attributes: {
					pageName: 'ny-bestilling'
				},
			});
		}
	}

	goToMyRequests(event) {
		this[NavigationMixin.Navigate]({
			type: 'comm__namedPage',
			attributes: {
				pageName: 'mine-bestillinger'
			}
		});
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
	goToPrevousPage() {
		this[NavigationMixin.Navigate]({
			type: 'comm__namedPage',
			attributes: {
				pageName: this.previousPage
			}
		});
	}

}
