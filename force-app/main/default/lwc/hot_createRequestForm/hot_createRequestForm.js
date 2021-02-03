import { LightningElement, wire, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import getRequestList from '@salesforce/apex/HOT_RequestListContoller.getRequestList';
import isProdFunction from '@salesforce/apex/GlobalCommunityHeaderFooterController.isProd';
import getPersonAccount from '@salesforce/apex/HOT_Utility.getPersonAccount';
import getOrdererDetails from '@salesforce/apex/HOT_Utility.getOrdererDetails';
import createAndUpdateWorkOrders from '@salesforce/apex/HOT_RequestHandler.createAndUpdateWorkOrders';
import getTimes from '@salesforce/apex/HOT_RequestListContoller.getTimes';
import createWorkOrders from '@salesforce/apex/HOT_CreateWorkOrderService.createWorkOrdersFromCommunity';



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
			if ((this.requests[i].StartTime__c < fields.StartTime__c && fields.StartTime__c < this.requests[i].EndTime__c
				||
				fields.StartTime__c < this.requests[i].StartTime__c && this.requests[i].StartTime__c < fields.EndTime__c
				||
				fields.StartTime__c == this.requests[i].StartTime__c && this.requests[i].EndTime__c == fields.EndTime__c)
				&&
				this.requests[i].Id != this.recordId
				&&
				this.requests[i].Status__c != 'Avlyst' && this.requests[i].Status__c != 'Annullert'
				&&
				fields.Type__c == 'Me' && this.requests[i].Account__c == this.personAccount.Id) {
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
		}
	}

	@track ordererForm = false;
	@track userForm = false;
	@track companyForm = false;
	@track requestForm = false;
	@track publicEventForm = false;

	@track currentRequestType = 'Me';
	get requestTypes() {
		return [
			{ label: 'For meg selv', value: 'Me' },
			{ label: 'For en bruker', value: 'User' },
			{ label: 'For en bruker, virksomheten betaler', value: 'Company' },
			{ label: 'Til et arrangement, virksomheten betaler', value: 'PublicEvent' }
		];
	}

	@track showNextButton = true;

	handleRequestTypeChange(event) {
		this.currentRequestType = event.detail.value;
		if (this.currentRequestType == 'PublicEvent') {
			this.publicEventForm = true;
		}
		else {
			this.publicEventForm = false;
			this.eventType = null;
		}
	}

	get eventTypes() {
		return [
			{ label: 'Idrettsarrangement', value: 'SportingEvent' },
			{ label: 'Annet', value: 'OtherEvent' },
		];
	}
	@track eventType = null;
	handleChoiceOfEvent(event) {
		this.eventType = event.detail.value;
		this.fieldValues.EventType__c = this.eventType;
	}


	@track error;
	@track fieldValues = {
		Name: "", Subject__c: "", StartTime__c: "", EndTime__c: "", MeetingStreet__c: "", MeetingPostalCity__c: "", MeetingPostalCode__c: "", Description__C: "",
		IsOtherEconomicProvicer__c: false, OrganizationNumber__c: "", InvoiceReference__c: "", AdditionalInvoiceText__c: "",
		UserName__c: "", UserPersonNumber__c: "", Orderer__c: "",
		OrdererEmail__c: "", OrdererPhone__c: "",
		Source__c: "Community", Type__c: "", EventType__c: "",
	};

	@track isPersonNumberValid = false;
	checkPersonNumber(event) {
		console.log("checkPersonNumber")
		let inputComponent = this.template.querySelector(".skjema").querySelector(".personNumber");
		this.fieldValues.UserPersonNumber__c = inputComponent.value;
		let regExp = RegExp("[0-7][0-9][0-1][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]");
		this.isPersonNumberValid = regExp.test(inputComponent.value);
		console.log("PersonNumber is valid? " + this.isPersonNumberValid);
	}
	reportValidityPersonNumberField() {
		let inputComponent = this.template.querySelector(".skjema").querySelector(".personNumber");
		if (!this.isPersonNumberValid) {
			inputComponent.setCustomValidity("Fødselsnummeret er ikke gyldig");
			inputComponent.focus();
		} else {
			inputComponent.setCustomValidity("");
		}
		inputComponent.reportValidity();
	}

	@track isOnlyOneTime = true;
	@track times = [];
	@track uniqueIdCounter = 0;
	@track requestIds = [];

	wiredTimesValue;
	@wire(getTimes, { requestIds: '$requestIds' })
	wiredTimes(result) {
		console.log('wiredTimes')
		this.wiredTimesValue = result.data;
		if (result.data) {
			if (result.data.length == 0) {
				console.log('result is empty')
				this.times = [{ "id": 0, "date": null, "startTime": null, "endTime": null, "isNew": 1 }];
			}
			else {
				console.log('Setting Times')
				//this.times = [...result.data];
				for (let timeMap of result.data) {
					let temp = new Object({ "id": timeMap.id, "date": timeMap.date, "startTime": timeMap.startTime, "endTime": timeMap.endTime, "isNew": 0 });
					this.times.push(temp);
				}
				this.validateExistingDateTimes();
			}
			this.isOnlyOneTime = this.times.length == 1;
			this.error = undefined;
		} else if (result.error) {
			this.error = result.error;
			this.times = undefined;
		}
	}


	setDate(event) {
		console.log(event.detail.value)
		let index = this.getIndexById(event.target.name);
		this.times[index].date = event.detail.value;
		var now = new Date();
		var tempTime = JSON.parse(JSON.stringify(now));
		tempTime = tempTime.split("");

		if (this.times[index].startTime == null || this.times[index].startTime == "") {
			if (Math.abs(parseFloat(tempTime[14] + tempTime[15]) - now.getMinutes()) <= 1) {
				tempTime[14] = '0';
				tempTime[15] = '0';
			}

			var first = parseFloat(tempTime[11]);
			var second = parseFloat(tempTime[12]);
			second = (second + 2) % 10;
			if (second == 0 || second == 1) {
				first = first + 1;
			}
			tempTime[11] = first.toString();
			tempTime[12] = second.toString();

			this.times[index].startTime = tempTime.join("").substring(11, 16);
			var first = parseFloat(tempTime[11]);
			var second = parseFloat(tempTime[12]);
			second = (second + 1) % 10;
			if (second == 0) {
				first = first + 1;
			}
			tempTime[11] = first.toString();
			tempTime[12] = second.toString();
			this.times[index].endTime = tempTime.join("").substring(11, 16);
		}
		this.validateDateInput(event, index);
	}
	setStartTime(event) {
		let index = this.getIndexById(event.target.name);
		console.log(event.detail.value)

		let tempTime = event.detail.value.split("");
		this.times[index].startTime = tempTime.join("").substring(0, 5);

		if (event.detail.value > this.times[index].endTime || this.times[index].endTime == null) {
			var first = parseFloat(tempTime[0]);
			var second = parseFloat(tempTime[1]);
			second = (second + 1) % 10;
			if (second == 0) {
				first = first + 1;
			}
			tempTime[0] = first.toString();
			tempTime[1] = second.toString();
			this.times[index].endTime = tempTime.join("").substring(0, 5);
		}
		this.validateDateInput(event, index);
	}

	setEndTime(event) {
		console.log(event.detail.value)
		const index = this.getIndexById(event.target.name);
		this.times[index].endTime = event.detail.value.substring(0, 5);
	}


	updateValues(event, index) {
		console.log("updateValues")
		let elements = event.target.parentElement.querySelector('.start-tid');
		elements.value = this.times[index].startTime;
		elements = event.target.parentElement.querySelector('.date');
		elements.value = this.times[index].date;
		elements = event.target.parentElement.querySelector('.slutt-tid');
		elements.value = this.times[index].endTime;
	}

	getIndexById(id) {
		var j = -1;
		for (var i = 0; i < this.times.length; i++) {
			if (this.times[i].id == id) {
				j = i;
			}
		}
		return j;
	}

	addTime(event) {
		this.uniqueIdCounter += 1;
		var newTime = {
			"id": this.uniqueIdCounter, "date": null, "startTime": null, "endTime": null, "isNew": 1
		};
		this.times.push(newTime);
		this.setIsOnlyOneTime();
	}
	setIsOnlyOneTime() {
		this.isOnlyOneTime = this.times.length == 1;
	}

	removeTime(event) {
		if (this.times.length > 1) {
			const index = this.getIndexById(event.target.name);
			if (index != -1) {
				this.times.splice(index, 1);
			}
		}
		this.setIsOnlyOneTime();
	}

	@track isAdvancedTimes = false;
	simpleTimes() {
		this.isAdvancedTimes = false;
		this.advancedTimeBackup = this.times;
		this.times = this.timesBackup;
		this.setIsOnlyOneTime();
	}
	@track timesBackup;
	@track advancedTimeBackup = [{ "id": 0, "date": null, "startTime": null, "endTime": null, "isNew": 1 }];
	advancedTimes() {
		this.isAdvancedTimes = true;
		this.timesBackup = this.times;
		this.times = this.advancedTimeBackup;
		this.setIsOnlyOneTime();
	}
	@track showWeekDays = false;
	repeatingOptions = [{ label: "Aldri", value: "Never" }, { label: "Daglig", value: "Daily" }, { label: "Uke", value: "Weekly" }, { label: "2. Uke", value: "Biweekly" }];
	repeatingOptionChosen = "";
	handleRepeatChoiceMade(event) {
		this.repeatingOptionChosen = event.detail.value;
		if (event.detail.value == "Weekly" || event.detail.value == "Biweekly") {
			this.showWeekDays = true;
		}
	}

	chosenDays = [];
	get days() {
		return [
			{ label: 'Mandag', value: 'monday' },
			{ label: 'Tirsdag', value: 'tuesday' },
			{ label: 'Onsdag', value: 'wednesday' },
			{ label: 'Torsdag', value: 'thursday' },
			{ label: 'Fredag', value: 'friday' },
			{ label: 'Lørdag', value: 'saturday' },
			{ label: 'Søndag', value: 'sunday' },
		];
	}
	handleDayChosen(event) {
		this.chosenDays = event.detail.value;
	}
	@track repeatingEndDate;
	setRepeatingEndDateDate(event) {
		this.repeatingEndDate = event.detail.value;
	}

	@track spin = false;

	handleSubmit(event) {
		console.log("handleSubmit");
		this.spin = true;
		event.preventDefault();
		const fields = event.detail.fields;

		if (fields) {

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

			let invalidIndex = [];
			console.log("validating times")
			for (let time of this.times) {
				console.log(JSON.stringify(time))
				if (!time.isValid) {
					invalidIndex.unshift(this.times.indexOf(time));
				}
			}

			console.log(invalidIndex)
			if (invalidIndex.length == 0 && this.isPersonNumberValid) {
				const isDuplicate = null; //this.isDuplicate(this.fieldValues); //Denne metoden fungerer ikke akkurat nå. Løses i TOLK-963
				if (isDuplicate == null) {
					console.log("Sumbitting")
					this.template.querySelector('.skjema').querySelector('lightning-record-edit-form').submit(this.fieldValues);
					console.log("submitted");
				}
				else {
					if (confirm("Du har allerede en bestilling på samme tidspunkt\n\nFortsett?")) {
						this.template.querySelector('.skjema').querySelector('lightning-record-edit-form').submit(this.fieldValues);
					}
					else {
						this.spin = false;
					}
				}
				window.scrollBy(0, 100);
				window.scrollBy(0, -100);
			}
			else {
				if (invalidIndex.length != 0) {
					let inputList = this.template.querySelectorAll('.dynamic-time-inputs-with-line_button');
					for (let index of invalidIndex) {
						let dateInputElement = inputList[index].querySelector('.date');
						this.throwInputValidationError(dateInputElement, dateInputElement.value ? 'Du kan ikke bestille tolk i fortiden.' : 'Fyll ut dette feltet.');
					}
				}
				if (!this.isPersonNumberValid) {
					this.reportValidityPersonNumberField();
				}
				this.spin = false;
			}
		}
	}

	@track showInformationSharingText = true;
	onHandleNeste() {
		this.fieldValues.Type__c = this.currentRequestType;

		let radioButtonGroup = this.template.querySelector(".skjema").querySelector(".requestTypeChoice");

		//Pressed "NESTE"
		let valid = true;
		if (this.currentRequestType != "") {
			this.spin = false;

			if (this.currentRequestType == 'User') {
				this.ordererForm = true;
				this.userForm = true;
			}
			else if (this.currentRequestType == 'Company') {
				this.ordererForm = true;
				this.userForm = true;
				this.companyForm = true;
				this.fieldValues.IsOtherEconomicProvicer__c = true;
			}
			else if (this.currentRequestType == 'PublicEvent') {
				let typeOfEventElement = this.template.querySelector(".skjema").querySelector(".type-arrangement");
				if (this.eventType == null) {
					typeOfEventElement.setCustomValidity("Du må velge type arrangement");
					typeOfEventElement.focus();
					this.spin = false;
					valid = false;
				}
				else {
					typeOfEventElement.setCustomValidity("");
					this.ordererForm = true;
					this.companyForm = true;
					this.fieldValues.IsOtherEconomicProvicer__c = true;
				}
				typeOfEventElement.reportValidity();

			}
			else {
				this.showInformationSharingText = false;
			}
			if (valid) {
				this.requestForm = true;
				this.showNextButton = false;
				radioButtonGroup.setCustomValidity("");
			}
		}
		else {
			radioButtonGroup.setCustomValidity("Du må velge type bestilling");
			radioButtonGroup.focus();
		}
		radioButtonGroup.reportValidity();
		if (this.currentRequestType == 'Me' || this.currentRequestType == 'PublicEvent') {
			this.isPersonNumberValid = true;
		}
	}

	validateExistingDateTimes() {
		for (let i = 0; i < this.times.length; i++) {
			let tempDate = this.formatDateTime(this.times[i]);
			tempDate = new Date(tempDate.date + ' ' + tempDate.startTime);
			this.times[i].isValid = this.validateDate(tempDate);
		}
	}
	validateDate(dateTime) {
		let nowTime = new Date();
		return dateTime.getTime() > nowTime.getTime()
	}
	throwInputValidationError(element, errorText) {
		element.setCustomValidity(errorText);
		if (errorText != "") {
			element.focus();
		}
		element.reportValidity();
	}
	validateDateInput(event, index) {
		let dateElement = event.target;
		let tempDate = this.formatDateTime(this.times[index]);
		tempDate = new Date(tempDate.date + ' ' + tempDate.startTime);
		if (!this.validateDate(tempDate)) {
			dateElement.setCustomValidity("Du kan ikke bestille tolk i fortiden.");
			dateElement.focus();
			this.times[index].isValid = false;
		}
		else {
			dateElement.setCustomValidity("");
			this.times[index].isValid = true;
		}
		dateElements.reportValidity();
	}

	formatDateTime(dateTime) {
		const year = dateTime.date.substring(0, 4);
		const month = dateTime.date.substring(5, 7);
		const day = dateTime.date.substring(8, 10);

		const startHour = dateTime.startTime.substring(0, 2);
		const startMinute = dateTime.startTime.substring(3, 5);
		const endHour = dateTime.endTime.substring(0, 2);
		const endMinute = dateTime.endTime.substring(3, 5);

		const newDateTime = {};
		newDateTime["id"] = dateTime.id;
		newDateTime["date"] = month + "/" + day + "/" + year;
		newDateTime["startTime"] = startHour + ":" + startMinute;
		newDateTime["endTime"] = endHour + ":" + endMinute;
		newDateTime["isValid"] = dateTime.isValid;
		newDateTime["isNew"] = dateTime.isNew;

		return newDateTime;
	}

	handleError(event) {
		console.log(JSON.stringify(event));
		this.spin = false;
	}

	@track isEditMode = false;
	handleSuccess(event) {
		console.log("handleSuccess");
		this.spin = false;
		var x = this.template.querySelector(".submitted-true");
		x.classList.remove('hidden');
		this.template.querySelector(".h2-successMessage").focus();
		x = this.template.querySelector(".submitted-false");
		x.classList.add('hidden');
		this.recordId = event.detail.id;


		let requestId = event.detail.id;
		let times = {};
		for (let dateTime of this.times) {
			dateTime = this.formatDateTime(dateTime);
			times[dateTime.id.toString()] = {
				"startTime": new Date(dateTime.date + " " + dateTime.startTime).getTime(),
				"endTime": new Date(dateTime.date + " " + dateTime.endTime).getTime(),
				"isNew": dateTime.isNew,
			};
		}
		if (times != {}) {
			if (this.isAdvancedTimes) {
				console.log("createWorkOrders ADVANCED");
				console.log(JSON.stringify(times));
				//String requestId, Map<String, Long> times, String recurringType, List<String> recurringDays, Long recurringEndDate
				let time = times["0"];
				let recurringType = this.repeatingOptionChosen;
				let recurringDays = this.chosenDays;
				let recurringEndDate = new Date(this.repeatingEndDate).getTime();
				console.log(requestId);
				console.log(JSON.stringify(time));
				console.log(recurringType);
				console.log(recurringDays);
				console.log(recurringEndDate);
				createWorkOrders({ requestId, times: time, recurringType, recurringDays, recurringEndDate });
			} else {
				console.log("createAndUpdateWorkOrders");
				createAndUpdateWorkOrders({ requestId, times })
			}
		}

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

		window.scrollTo(0, 0);
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

				delete this.fieldValues.Account__c;
				delete this.fieldValues.Company__c;
				delete this.fieldValues.StartTime__c;
				delete this.fieldValues.EndTime__c;

				this.sameLocation = this.fieldValues.MeetingStreet__c == this.fieldValues.InterpretationStreet__c;
				if (!this.sameLocation) {
					this.value = 'no';
				}
				this.isEditMode = parsed_params.edit != null;
				this.showNextButton = !(parsed_params.edit != null || parsed_params.copy != null);
				if (!this.showNextButton) {
					this.requestForm = true;
					if (this.fieldValues.Type__c != 'Me' && this.fieldValues.Type__c != null) {
						this.ordererForm = true;
						this.userForm = this.fieldValues.Type__c != 'PublicEvent';
						this.companyForm = this.fieldValues.Type__c != 'User';
					}
				}
				if (!!parsed_params.copy) {
					delete this.fieldValues.Id;
				}
				else {
					console.log('Is Edit: Refreshing apex times')
					this.recordId = this.fieldValues.Id;
					let requestIds = [];
					requestIds.push(this.fieldValues.Id);
					this.requestIds = requestIds;
					refreshApex(this.wiredTimesValue);
				}

				if (this.fieldValues.Type__c == 'PublicEvent') {
					this.fieldValues.EventType__c = this.fieldValues.EventType__c == "Annet" ? "OtherEvent" : "SportingEvent";
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
		window.scrollTo(0, 0);
		this[NavigationMixin.Navigate]({
			type: 'comm__namedPage',
			attributes: {
				pageName: this.previousPage
			}
		});
	}

}
