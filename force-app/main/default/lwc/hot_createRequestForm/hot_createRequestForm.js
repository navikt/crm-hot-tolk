import { LightningElement, wire, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getRequestList from '@salesforce/apex/HOT_RequestListContoller.getRequestList';
import isProdFunction from '@salesforce/apex/GlobalCommunityHeaderFooterController.isProd';
import ACCOUNTID from '@salesforce/apex/HOT_Utility.getPersonAccountId';

export default class RecordFormCreateExample extends NavigationMixin(LightningElement) {
	@track reRender = 0;

	@track isProd;
	@track error;
	@wire(isProdFunction)
	wiredIsProd({ error, data }) {
		this.isProd = data;
	}


	@track submitted = false; // if:false={submitted}
	hide = true; //@track edit = false; When file-upload is ready, fix this.
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

	@track defaultForm = true;
	@track userForm = false;
	@track companyForm = false;
	@track requestForm = true;

	currentRequestType = "";
	get requestTypes() {
		return [
			{ label: 'Bestille for bruker', value: 'user' },
			{ label: 'Bestille for bruker, virksomheten betaler', value: 'user_company' },
			{ label: 'Bestille til arrangement, virksomheten betaler', value: 'company' }
		];
	}

	handleRequestTypeSubmit(event) {
		event.preventDefault();
		const fields = event.detail.fields;

		if (this.currentRequestType != "" && fields != null) {
			this.fieldValues.OrdererEmail__c = fields.OrdererEmail__c;
			this.fieldValues.OrdererPhone__c = fields.OrdererPhone__c;

			if (this.currentRequestType.includes('user')) {
				this.userForm = true;
			}
			else {
				this.companyForm = true;
			}
		}
		else {
			console.log("ERROR")
		}
	}

	handleRequestTypeChange(event) {
		this.currentRequestType = event.detail.value;
	}


	handleUserFormSubmit(event) {
		event.preventDefault();

		const fields = event.detail.fields;

		this.fieldValues.UserName__c = fields.UserName__c;
		this.fieldValues.PersonNumber__c = fields.PersonNumber__c;

		if (this.currentRequestType.includes('company')) {
			this.companyForm = true;
		}
		else {
			this.requestForm = true;
		}

	}

	handleCompanyFormSubmit(event) {
		event.preventDefault();

		const fields = event.detail.fields;

		this.fieldValues.OrganizationNumber__c = fields.OrganizationNumber__c;
		this.fieldValues.InvoiceReference__c = fields.InvoiceReference__c;
		this.fieldValues.AdditionalInvoiceText__c = fields.AdditionalInvoiceText__c;
		this.fieldValues.OrderNumber__c = fields.OrderNumber__c;

		this.requestForm = true;
	}




	@track error;
	@track fieldValues = {
		Name: "", Subject__c: "", StartTime__c: "", EndTime__c: "", MeetingStreet__c: "", MeetingPostalCity__c: "", MeetingPostalCode__c: "", Description__C: "",
		OrganizationNumber__c: "", InvoiceReference__c: "", AdditionalInvoiceText__c: "", OrderNumber__c: "",
		UserName__c: "", PersonNumber__c: "", Orderer__c: "",
		OrdererEmail__c: "", OrdererPhone__c: "",
	};


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
		event.preventDefault();

		const fields = event.detail.fields;
		this.fieldValues.Orderer__c = ACCOUNTID();
		for (const k in fields) {
			this.fieldValues[k] = fields[k];
		}
		if (this.sameLocation) {
			this.fieldValues.InterpretationStreet__c = fields.MeetingStreet__c;
			this.fieldValues.InterpretationPostalCode__c = fields.MeetingPostalCode__c;
			this.fieldValues.InterpretationPostalCity__c = fields.MeetingPostalCity__c;
		}


		if (fields) {
			this.spin = true;
			const isDuplicate = this.isDuplicate(this.fieldValues);
			if (isDuplicate == null) {
				this.template.querySelector('div.bestilling-info-skjema').querySelector('lightning-record-edit-form').submit(this.fieldValues);
			}

			else {
				if (confirm("Du har allerede en bestilling på samme tidspunkt\nTema: " + this.requests[isDuplicate].Subject__c +
					"\nFra: " + this.formatDateTime(this.requests[isDuplicate].StartTime__c) +
					"\nTil: " + this.formatDateTime(this.requests[isDuplicate].EndTime__c)
					+ "\n\nFortsett?")) {
					this.template.querySelector('div.bestilling-info-skjema').querySelector('lightning-record-edit-form').submit(this.fieldValues);
				}
			}
			this.spin = false;
		}
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

	}
	handleSuccess(event) {
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
			if (parsed_params.notDefault != null) {
				this.defaultForm = false;
				this.requestForm = false;
			}


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
				this.edit = parsed_params.edit != null;
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
