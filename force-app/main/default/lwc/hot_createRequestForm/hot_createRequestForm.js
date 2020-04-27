import { LightningElement, wire, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getRequestList from '@salesforce/apex/HOT_RequestListContoller.getRequestList';

export default class RecordFormCreateExample extends NavigationMixin(LightningElement) {
	@track reRender = 0;

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

	@track error;
	@track fieldValues = { Name: "", Subject__c: "", StartTime__c: "", EndTime__c: "", MeetingStreet__c: "", MeetingPostalCity__c: "", MeetingPostalCode__c: "", Description__C: "" };


	@track startTime;
	@track endTime;
	@track date;
	@track times = [{
		"id": 0, "date": null, "startTime": null, "endTime": null
	}];
	@track uniqueIdCounter = 1;

	setDate(event) {
		const index = this.getIndexById(event.target.name);
		this.times[index].date = event.detail.value;

		var now = new Date();
		var tempTime = JSON.parse(JSON.stringify(now));
		tempTime = tempTime.split("");

		if (this.times[index].startTime == null) {
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

			this.times[index].startTime = tempTime.join("").substring(11, 23);
			var first = parseFloat(tempTime[11]);
			var second = parseFloat(tempTime[12]);
			second = (second + 1) % 10;
			if (second == 0) {
				first = first + 1;
			}
			tempTime[11] = first.toString();
			tempTime[12] = second.toString();
			this.times[index].endTime = tempTime.join("").substring(11, 23);
		}
		this.updateValues(event, index);
	}
	setStartTime(event) {
		const index = this.getIndexById(event.target.name);
		var tempTime = event.detail.value.split("");
		this.times[index].startTime = event.detail.value;

		if (event.detail.value > this.times[index].endTime || this.times[index].endTime == null) {
			var first = parseFloat(tempTime[0]);
			var second = parseFloat(tempTime[1]);
			second = (second + 1) % 10;
			if (second == 0) {
				first = first + 1;
			}
			tempTime[0] = first.toString();
			tempTime[1] = second.toString();
			this.times[index].endTime = tempTime.join("");
		}
		this.updateValues(event, index);
	}

	setEndTime(event) {
		const index = this.getIndexById(event.target.name);
		this.times[index].endTime = event.detail.value;
		this.updateValues(event, index);
	}


	updateValues(event, index) {
		console.log(JSON.stringify(this.times));
		var elements = event.target.parentElement.querySelector('.start-tid');
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
		var newTime = {
			"id": this.uniqueIdCounter, "date": null, "startTime": null, "endTime": null
		};
		this.times.push(newTime);
		this.uniqueIdCounter += 1;
	}

	removeTime(event) {
		if (this.times.length > 1) {
			const index = this.getIndexById(event.target.name);
			if (index != -1) {
				this.times.splice(index, 1);
			}
		}
	}


	handleSubmit(event) {
		event.preventDefault();

		const fields = event.detail.fields;
		fields.StartTime__c = DateTime.newInstance(this.date, this.startTime);
		fields.EndTime__c = DateTime.newInstance(this.date, this.endTime);

		if (this.sameLocation) {
			fields.InterpretationStreet__c = fields.MeetingStreet__c;
			fields.InterpretationPostalCode__c = fields.MeetingPostalCode__c;
			fields.InterpretationPostalCity__c = fields.MeetingPostalCity__c;
		}
		console.log(JSON.stringify(fields));
		if (fields) {
			const isDuplicate = this.isDuplicate(fields);
			if (this.isDuplicate(fields) == null) {
				this.template.querySelector('lightning-record-edit-form').submit(fields);
			}

			else {
				if (confirm("Du har allerede en bestilling med temaet " + this.requests[isDuplicate].Subject__c +
					"\nFortsette?")) {
					this.template.querySelector('lightning-record-edit-form').submit(fields);
				}
			}
		}
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

	}
	handleUploadFinished(event) {
		// Get the list of uploaded files
		const uploadedFiles = event.detail.files;
		alert(uploadedFiles.length + " filer ble lastet opp.");
	}

	toggled() {
		this.sameLocation = !this.sameLocation;
	}


	previousPage;
	connectedCallback() {
		let testURL = window.location.href;
		let newURL = new URL(testURL).searchParams;
		if (JSON.parse(newURL.get("fromList")) != null) {
			this.previousPage = 'mine-bestillinger';
		}
		else {
			this.previousPage = 'home';
		}
		if (JSON.parse(newURL.get("fieldValues")) != null) {

			this.fieldValues = JSON.parse(newURL.get("fieldValues"));
			this.sameLocation = this.fieldValues.MeetingStreet__c == this.fieldValues.InterpretationStreet__c;
			if (!this.sameLocation) {
				this.value = 'no';
			}

			this.recordId = this.fieldValues.Id;
			this.edit = JSON.parse(newURL.get("edit")) != null;
		}
	}


	//Navigation functions
	goToMyRequests() {
		this[NavigationMixin.Navigate]({
			type: 'comm__namedPage',
			attributes: {
				pageName: 'mine-bestillinger'
			}
		});
	}

	goHome() {
		this[NavigationMixin.Navigate]({
			type: 'comm__namedPage',
			attributes: {
				pageName: this.previousPage,
			}
		});
	}
}