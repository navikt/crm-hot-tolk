import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import getRequestList from '@salesforce/apex/HOT_RequestListContoller.getRequestList';
import isProdFunction from '@salesforce/apex/GlobalCommunityHeaderFooterController.isProd';
import getPersonAccount from '@salesforce/apex/HOT_Utility.getPersonAccount';
import getOrdererDetails from '@salesforce/apex/HOT_Utility.getOrdererDetails';
import createAndUpdateWorkOrders from '@salesforce/apex/HOT_RequestHandler.createAndUpdateWorkOrders';
import getTimes from '@salesforce/apex/HOT_RequestListContoller.getTimes';
import createWorkOrders from '@salesforce/apex/HOT_CreateWorkOrderService.createWorkOrdersFromCommunity';
import checkDuplicates from '@salesforce/apex/HOT_DuplicateHandler.checkDuplicates';
import { validate } from 'c/validationController';
import {
    recurringTypeValidations,
    recurringDaysValidations,
    recurringEndDateValidations
} from './hot_createRequestForm_validationRules';
import uploadFile from '@salesforce/apex/HOT_RequestListContoller.uploadFile';

export default class RecordFormCreateExample extends NavigationMixin(LightningElement) {
    @track reRender = 0;

    @track isProd;
    @wire(isProdFunction)
    wiredIsProd({ data }) {
        this.isProd = data;
    }

    @track submitted = false; // if:false={submitted}
    acceptedFileFormats = '[.pdf, .png, .jpg, .jpeg, .doc, .docx, .xls, .xlsx, .ppt, pptx, .txt, .rtf]';

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
        let tempRequests = [];
        for (let i = 0; i < this.allRequests.length; i++) {
            if (
                this.allRequests[i].ExternalRequestStatus__c !== 'Avlyst' &&
                this.allRequests[i].ExternalRequestStatus__c !== 'Dekket' &&
                this.allRequests[i].ExternalRequestStatus__c !== 'Udekket'
            ) {
                tempRequests.push(this.allRequests[i]);
            }
        }
        this.requests = tempRequests;
    }

    @track sameLocation = true;
    value = 'yes';
    get options() {
        return [
            { label: 'Ja', value: 'yes' },
            { label: 'Nei', value: 'no' }
        ];
    }
    @track personAccount = { Id: '', Name: '' };
    @track ordererDetails = { OrdererEmail__c: '', OrdererPhone__c: '' };

    @wire(getPersonAccount)
    wiredGetPersonAccount(result) {
        if (result.data) {
            this.personAccount.Id = result.data.AccountId;
            this.personAccount.Name = result.data.Account.CRM_Person__r.CRM_FullName__c;
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
            {
                label: 'Til et arrangement, virksomheten betaler',
                value: 'PublicEvent'
            }
        ];
    }

    @track showNextButton = true;

    handleRequestTypeChange(event) {
        this.currentRequestType = event.detail.value;
        if (this.currentRequestType === 'PublicEvent') {
            this.publicEventForm = true;
        } else {
            this.publicEventForm = false;
            this.eventType = null;
        }
    }

    get eventTypes() {
        return [
            { label: 'Idrettsarrangement', value: 'SportingEvent' },
            { label: 'Annet', value: 'OtherEvent' }
        ];
    }
    @track eventType = null;
    handleChoiceOfEvent(event) {
        this.eventType = event.detail.value;
    }

    @track fieldValues = {
        Name: '',
        Subject__c: '',
        StartTime__c: '',
        EndTime__c: '',
        MeetingStreet__c: '',
        MeetingPostalCity__c: '',
        MeetingPostalCode__c: '',
        Description__C: '',
        IsOtherEconomicProvicer__c: false,
        OrganizationNumber__c: '',
        InvoiceReference__c: '',
        AdditionalInvoiceText__c: '',
        UserName__c: '',
        UserPersonNumber__c: '',
        Orderer__c: '',
        OrdererEmail__c: '',
        OrdererPhone__c: '',
        Source__c: 'Community',
        Type__c: '',
        EventType__c: ''
    };

    @track isPersonNumberValid = true;
    checkPersonNumber() {
        let inputComponent = this.template.querySelector('.skjema').querySelector('.personNumber');
        this.fieldValues.UserPersonNumber__c = inputComponent.value;
        let regExp = RegExp('[0-7][0-9][0-1][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]');
        this.isPersonNumberValid = regExp.test(inputComponent.value);
    }
    reportValidityPersonNumberField() {
        let inputComponent = this.template.querySelector('.skjema').querySelector('.personNumber');
        if (!this.isPersonNumberValid) {
            inputComponent.setCustomValidity('Fødselsnummeret er ikke gyldig');
            inputComponent.focus();
        } else {
            inputComponent.setCustomValidity('');
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
        this.wiredTimesValue = result.data;
        if (result.data) {
            if (result.data.length === 0) {
                this.times = [
                    {
                        id: 0,
                        date: null,
                        startTime: null,
                        endTime: null,
                        isNew: 1
                    }
                ];
            } else {
                //this.times = [...result.data];
                for (let timeMap of result.data) {
                    let temp = new Object({
                        id: timeMap.id,
                        date: timeMap.date,
                        startTime: timeMap.startTime,
                        endTime: timeMap.endTime,
                        isNew: 0
                    });
                    this.times.push(temp);
                }
                this.validateExistingDateTimes();
            }
            this.isOnlyOneTime = this.times.length === 1;
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            this.times = undefined;
        }
    }

    setDate(event) {
        let index = this.getIndexById(event.target.name);
        this.times[index].date = event.detail.value;
        let now = new Date();
        let tempTime = JSON.parse(JSON.stringify(now));
        tempTime = tempTime.split('');

        if (this.times[index].startTime === null || this.times[index].startTime === '') {
            if (Math.abs(parseFloat(tempTime[14] + tempTime[15]) - now.getMinutes()) <= 1) {
                tempTime[14] = '0';
                tempTime[15] = '0';
            }

            let first = parseFloat(tempTime[11]);
            let second = parseFloat(tempTime[12]);
            second = (second + 2) % 10;
            if (second === 0 || second === 1) {
                first = first + 1;
            }
            tempTime[11] = first.toString();
            tempTime[12] = second.toString();

            this.times[index].startTime = tempTime.join('').substring(11, 16);
            first = parseFloat(tempTime[11]);
            second = parseFloat(tempTime[12]);
            second = (second + 1) % 10;
            if (second === 0) {
                first = first + 1;
            }
            tempTime[11] = first.toString();
            tempTime[12] = second.toString();
            this.times[index].endTime = tempTime.join('').substring(11, 16);
        }
        this.validateDateInput(event, index);
    }
    setStartTime(event) {
        let index = this.getIndexById(event.target.name);
        let tempTime = event.detail.value.split('');
        this.times[index].startTime = tempTime.join('').substring(0, 5);

        if (event.detail.value > this.times[index].endTime || this.times[index].endTime === null) {
            let first = parseFloat(tempTime[0]);
            let second = parseFloat(tempTime[1]);
            second = (second + 1) % 10;
            if (second === 0) {
                first = first + 1;
            }
            tempTime[0] = first.toString();
            tempTime[1] = second.toString();
            this.times[index].endTime = tempTime.join('').substring(0, 5);
        }
        this.validateDateInput(event, index);
    }

    setEndTime(event) {
        const index = this.getIndexById(event.target.name);
        this.times[index].endTime = event.detail.value.substring(0, 5);
    }

    updateValues(event, index) {
        let elements = event.target.parentElement.querySelector('.start-tid');
        elements.value = this.times[index].startTime;
        elements = event.target.parentElement.querySelector('.date');
        elements.value = this.times[index].date;
        elements = event.target.parentElement.querySelector('.slutt-tid');
        elements.value = this.times[index].endTime;
    }

    getIndexById(id) {
        let j = -1;
        for (let i = 0; i < this.times.length; i++) {
            if (this.times[i].id === id) {
                j = i;
            }
        }
        return j;
    }

    addTime() {
        this.uniqueIdCounter += 1;
        let newTime = {
            id: this.uniqueIdCounter,
            date: null,
            startTime: null,
            endTime: null,
            isNew: 1
        };
        this.times.push(newTime);
        this.setIsOnlyOneTime();
    }
    setIsOnlyOneTime() {
        this.isOnlyOneTime = this.times.length === 1;
    }

    removeTime(event) {
        if (this.times.length > 1) {
            const index = this.getIndexById(event.target.name);
            if (index !== -1) {
                this.times.splice(index, 1);
            }
        }
        this.setIsOnlyOneTime();
    }

    @track isAdvancedTimes = false;
    @track timesBackup;
    advancedTimes(event) {
        this.isAdvancedTimes = event.detail.checked;
        if (this.isAdvancedTimes) {
            this.timesBackup = this.times;
            this.times = [this.times[0]];
        } else {
            this.times = this.timesBackup;
        }
        this.setIsOnlyOneTime();
    }
    @track isRepeating = false;
    @track showWeekDays = false;
    repeatingOptions = [
        { label: 'Hver dag', value: 'Daily' },
        { label: 'Hver uke', value: 'Weekly' },
        { label: 'Hver 2. Uke', value: 'Biweekly' }
    ];
    repeatingOptionChosen = '';
    handleRepeatChoiceMade(event) {
        this.repeatingOptionChosen = event.detail.value;
        if (event.detail.value === 'Weekly' || event.detail.value === 'Biweekly') {
            this.showWeekDays = true;
        } else {
            this.showWeekDays = false;
        }
        if (event.detail.value !== 'Never') {
            this.isRepeating = true;
        } else {
            this.isRepeating = false;
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
            { label: 'Søndag', value: 'sunday' }
        ];
    }
    handleDayChosen(event) {
        this.chosenDays = event.detail.value;
    }
    @track repeatingEndDate;
    setRepeatingEndDateDate(event) {
        this.repeatingEndDate = event.detail.value;
        let recurringEndDateElement = this.template.querySelector('.recurringEndDate');
        validate(
            recurringEndDateElement,
            recurringEndDateValidations,
            this.repeatingOptionChosen,
            this.times[0].date,
            this.chosenDays
        );
    }

    @track spin = false;

    handleAdvancedTimeValidations() {
        let typeElement = this.template.querySelector('.recurringType');
        let recurringTypeValid = validate(typeElement, recurringTypeValidations).length === 0;

        let daysElement = this.template.querySelector('.recurringDays');
        let recurringDaysValid =
            validate(daysElement, recurringDaysValidations, this.repeatingOptionChosen).length === 0;

        let recurringEndDateElement = this.template.querySelector('.recurringEndDate');
        let recurringEndDateValid =
            validate(
                recurringEndDateElement,
                recurringEndDateValidations,
                this.repeatingOptionChosen,
                this.times[0].date,
                this.chosenDays
            ).length === 0;

        return recurringTypeValid && recurringDaysValid && recurringEndDateValid;
    }

    checkboxValue = false;
    handleCheckboxValue(event) {
        this.checkboxValue = event.detail;
        this.template.querySelector('c-checkbox').validationHandler(''); // Clear validation when clicking checkbox. Only validate on Submit.
    }

    handleValidation() {
        let checkboxValid = true;
        if (this.fileData.length > 0) {
            if (!this.checkboxValue) {
                this.template.querySelector('c-checkbox').validationHandler('Sjekkboks må være fylt ut');
            }
            checkboxValid = this.checkboxValue;
        }
        let datetimeValid = this.handleDatetimeValidation().length === 0;
        let advancedValid = true;

        if (this.isAdvancedTimes) {
            advancedValid = this.handleAdvancedTimeValidations();
        }
        return datetimeValid && this.handlePersonNumberValidation() && advancedValid && checkboxValid;
    }

    handleDatetimeValidation() {
        let invalidIndex = [];
        for (let time of this.times) {
            if (!time.isValid) {
                invalidIndex.unshift(this.times.indexOf(time));
            }
        }
        if (invalidIndex.length !== 0) {
            let inputList = this.template.querySelectorAll('.dynamic-time-inputs-with-line_button');
            for (let index of invalidIndex) {
                let dateInputElement = inputList[index].querySelector('.date');
                this.throwInputValidationError(
                    dateInputElement,
                    dateInputElement.value ? 'Du kan ikke bestille tolk i fortiden.' : 'Fyll ut dette feltet.'
                );
            }
        }
        return invalidIndex;
    }
    handlePersonNumberValidation() {
        if (!this.isPersonNumberValid) {
            this.reportValidityPersonNumberField();
        }
        return this.isPersonNumberValid;
    }

    async handleSubmit(event) {
        this.spin = true;
        event.preventDefault();
        const fields = event.detail.fields;

        if (fields) {
            this.setFieldValues(fields);
            let isValid = this.handleValidation();
            if (isValid) {
                if (!this.isAdvancedTimes) {
                    let accountId = this.personAccount.Id;
                    let times = this.timesListToObject(this.times);
                    let duplicateRequests = [];
                    if (this.fieldValues.Type__c === 'Me') {
                        duplicateRequests = await checkDuplicates({
                            accountId: accountId,
                            times: times
                        });
                    }
                    if (duplicateRequests.length === 0) {
                        this.submit();
                    } else {
                        let warningMessage = 'Du har allerede bestillinger i dette tidsrommet:';
                        for (let request of duplicateRequests) {
                            warningMessage += '\nEmne: ' + request.Subject__c;
                            warningMessage += '\nPeriode: ' + request.SeriesPeriod__c;
                        }
                        if (confirm(warningMessage)) {
                            this.submit();
                        } else {
                            this.spin = false;
                        }
                    }
                } else {
                    this.submit();
                }
            } else {
                this.spin = false;
            }
        }
    }
    submit() {
        this.template.querySelector('.skjema').querySelector('lightning-record-edit-form').submit(this.fieldValues);
        window.scrollBy(0, 100);
        window.scrollBy(0, -100);
    }

    setFieldValues(fields) {
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
    }

    myselfForm = false;
    @track showInformationSharingText = true;
    onHandleNeste() {
        this.fieldValues.Type__c = this.currentRequestType;
        this.fieldValues.EventType__c = this.eventType;

        let radioButtonGroup = this.template.querySelector('.skjema').querySelector('.requestTypeChoice');

        //Pressed "NESTE"
        let valid = true;
        if (this.currentRequestType !== '') {
            this.spin = false;

            if (this.currentRequestType === 'User') {
                this.ordererForm = true;
                this.userForm = true;
            } else if (this.currentRequestType === 'Me') {
                this.myselfForm = true;
            } else if (this.currentRequestType === 'Company') {
                this.ordererForm = true;
                this.userForm = true;
                this.companyForm = true;
                this.fieldValues.IsOtherEconomicProvicer__c = true;
            } else if (this.currentRequestType === 'PublicEvent') {
                let typeOfEventElement = this.template.querySelector('.skjema').querySelector('.type-arrangement');
                if (this.eventType === null) {
                    typeOfEventElement.setCustomValidity('Du må velge type arrangement');
                    typeOfEventElement.focus();
                    this.spin = false;
                    valid = false;
                } else {
                    typeOfEventElement.setCustomValidity('');
                    this.ordererForm = true;
                    this.companyForm = true;
                    this.fieldValues.IsOtherEconomicProvicer__c = true;
                }
                typeOfEventElement.reportValidity();
            } else {
                this.showInformationSharingText = false;
            }
            if (valid) {
                this.requestForm = true;
                this.showNextButton = false;
                radioButtonGroup.setCustomValidity('');
            }
        } else {
            radioButtonGroup.setCustomValidity('Du må velge type bestilling');
            radioButtonGroup.focus();
        }
        radioButtonGroup.reportValidity();
        if (this.currentRequestType === 'User' || this.currentRequestType === 'Company') {
            this.isPersonNumberValid = false;
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
        return dateTime.getTime() > nowTime.getTime();
    }
    throwInputValidationError(element, errorText) {
        element.setCustomValidity(errorText);
        if (errorText !== '') {
            element.focus();
        }
        element.reportValidity();
    }
    validateDateInput(event, index) {
        let dateElement = event.target;
        let tempDate = this.formatDateTime(this.times[index]);
        tempDate = new Date(tempDate.date + ' ' + tempDate.startTime);
        if (!this.validateDate(tempDate)) {
            dateElement.setCustomValidity('Du kan ikke bestille tolk i fortiden.');
            dateElement.focus();
            this.times[index].isValid = false;
        } else {
            dateElement.setCustomValidity('');
            this.times[index].isValid = true;
        }
        dateElement.reportValidity();
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
        newDateTime.id = dateTime.id;
        newDateTime.date = month + '/' + day + '/' + year;
        newDateTime.startTime = startHour + ':' + startMinute;
        newDateTime.endTime = endHour + ':' + endMinute;
        newDateTime.isValid = dateTime.isValid;
        newDateTime.isNew = dateTime.isNew;

        return newDateTime;
    }

    handleError() {
        this.spin = false;
    }

    timesListToObject(list) {
        let times = {};
        for (let dateTime of list) {
            dateTime = this.formatDateTime(dateTime);
            times[dateTime.id.toString()] = {
                startTime: new Date(dateTime.date + ' ' + dateTime.startTime).getTime(),
                endTime:
                    dateTime.startTime < dateTime.endTime
                        ? new Date(dateTime.date + ' ' + dateTime.endTime).getTime()
                        : new Date(dateTime.date + ' ' + dateTime.endTime).getTime() + 24 * 60 * 60 * 1000,
                isNew: dateTime.isNew
            };
        }
        return times;
    }

    @track isEditMode = false;
    handleSuccess(event) {
        this.spin = false;
        let x = this.template.querySelector('.submitted-true');
        x.classList.remove('hidden');
        this.template.querySelector('.h2-successMessage').focus();
        x = this.template.querySelector('.submitted-false');
        x.classList.add('hidden');
        this.recordId = event.detail.id;
        let requestId = event.detail.id;
        this.handleFileUpload();
        let times = this.timesListToObject(this.times);
        if (times !== {}) {
            if (this.isAdvancedTimes) {
                //String requestId, Map<String, Long> times, String recurringType, List<String> recurringDays, Long recurringEndDate
                let time = times['0'];
                let recurringType = this.repeatingOptionChosen;
                let recurringDays = this.chosenDays;
                let recurringEndDate = new Date(this.repeatingEndDate).getTime();
                createWorkOrders({
                    requestId,
                    times: time,
                    recurringType,
                    recurringDays,
                    recurringEndDate
                });
            } else {
                createAndUpdateWorkOrders({ requestId, times });
            }
        }

        window.scrollTo(0, 0);
    }

    showModal() {
        this.template.querySelector('c-alertdialog').showModal();
    }

    focusCheckbox() {
        this.template.querySelector('c-checkbox').focusCheckbox();
    }

    isDrop = false;
    dropHandler(event) {
        event.preventDefault();
        this.isDrop = true;
        this.onFileUpload(event);
    }

    dragOverHandler(event) {
        event.preventDefault();
    }

    onFileButtonClick(event) {
        const index = event.currentTarget.dataset.index;
        if (this.fileData.length < index) {
            return;
        }
        this.fileData.splice(index, 1);
        this.filesChanged = false; // Make boolean change value to refresh filelist
        this.filesChanged = true;
        if (this.fileData.length === 0) {
            this.showOrHideCheckbox(false);
        }
        this.setCheckboxContent();
    }

    setCheckboxContent() {
        this.checkboxContent =
            this.fileData.length > 1
                ? 'Dokumentene som er lagt ved gir bakgrunnsinformasjon om mitt innmeldte behov for tolk. Informasjonen er nødvendig for at behovet skal bli forsvarlig dekket. Jeg er klar over at vedleggene vil bli delt med tolken(e) som blir tildelt oppdraget.'
                : 'Dokumentet som er lagt ved gir bakgrunnsinformasjon om mitt innmeldte behov for tolk. Informasjonen er nødvendig for at behovet skal bli forsvarlig dekket. Jeg er klar over at vedlegget vil bli delt med tolken(e) som blir tildelt oppdraget.';
    }
    fileButtonLabel;
    onFileFocus(event) {
        this.fileButtonLabel = '';
        const index = event.currentTarget.dataset.index;
        this.fileButtonLabel = 'Slett vedlegg ' + this.fileData[index].filename;
    }

    showOrHideCheckbox(show) {
        if (show) {
            this.template.querySelector('.checkboxClass').classList.remove('hidden');
            this.focusCheckbox();
        } else {
            this.template.querySelector('.checkboxClass').classList.add('hidden');
        }
    }

    noCancelButton = false;
    filesChanged = false; // If true shows new files
    header = 'Samtykke';
    checkboxContent;
    modalContent;
    fileData = [];
    async onFileUpload(event) {
        try {
            const result = this.isDrop
                ? await Promise.all([...event.dataTransfer.files].map((item) => this.readFile(item)))
                : await Promise.all([...event.target.files].map((item) => this.readFile(item)));
            result.forEach((item) => {
                // Only push new files
                if (this.fileData.findIndex((storedItem) => storedItem.base64 === item.base64) === -1) {
                    this.fileData.push(item);
                    this.filesChanged = false; // Make boolean change value to refresh filelist
                    this.filesChanged = true;
                }
            });
            this.setCheckboxContent();
            this.showOrHideCheckbox(true);
        } catch (err) {
            this.fileData = [];
            this.header = 'Noe gikk galt';
            this.modalContent = 'Filen(e) kunne ikke lastes opp. Feilmelding: ' + err;
            this.noCancelButton = true;
            this.showModal();
        }
        this.isDrop = false;
    }

    setButtonStyleOnFocus() {
        let inputEle = this.template.querySelector('[data-id="file-input"]');
        if (this.template.activeElement === inputEle) {
            document.documentElement.style.setProperty('--outline', 'none');
            document.documentElement.style.setProperty('--boxShadow', '0 0 0 3px #00347d');
        } else {
            document.documentElement.style.setProperty('--outline', 'none');
            document.documentElement.style.setProperty('--boxShadow', 'none');
        }
    }

    readFile(file) {
        return new Promise((resolve) => {
            const reader = new FileReader();
            reader.onload = () => {
                resolve({
                    filename: file.name,
                    base64: reader.result.split(',')[1],
                    recordId: this.recordId // Will be null here since record is not created yet. Add it on submit in handleFileUpload().
                });
            };
            reader.readAsDataURL(file);
        });
    }

    handleFileUpload() {
        this.fileData.forEach((item) => {
            item.recordId = this.recordId;
            const { base64, filename, recordId } = item;
            uploadFile({ base64, filename, recordId });
        });
        this.fileData = null;
    }

    toggled() {
        this.sameLocation = !this.sameLocation;
    }

    previousPage = 'home';

    connectedCallback() {
        window.scrollTo(0, 0);
        let testURL = window.location.href;
        let params = testURL.split('?')[1];

        function parse_query_string(query) {
            let vars = query.split('&');
            let query_string = {};
            for (let i = 0; i < vars.length; i++) {
                let pair = vars[i].split('=');
                let key = decodeURIComponent(pair[0]);
                let value = decodeURIComponent(pair[1]);
                // If first entry with this name
                if (typeof query_string[key] === 'undefined') {
                    query_string[key] = decodeURIComponent(value);
                    // If second entry with this name
                } else if (typeof query_string[key] === 'string') {
                    let arr = [query_string[key], decodeURIComponent(value)];
                    query_string[key] = arr;
                    // If third or later entry with this name
                } else {
                    query_string[key].push(decodeURIComponent(value));
                }
            }
            return query_string;
        }

        if (params !== undefined) {
            let parsed_params = parse_query_string(params);
            if (parsed_params.fromList != null) {
                this.previousPage = 'mine-bestillinger';
            }

            if (parsed_params.fieldValues != null) {
                this.fieldValues = JSON.parse(parsed_params.fieldValues);

                delete this.fieldValues.Account__c;
                delete this.fieldValues.Company__c;
                delete this.fieldValues.StartTime__c;
                delete this.fieldValues.EndTime__c;

                this.sameLocation = this.fieldValues.MeetingStreet__c === this.fieldValues.InterpretationStreet__c;
                if (!this.sameLocation) {
                    this.value = 'no';
                }
                this.isEditMode = parsed_params.edit != null;
                this.showNextButton = !(parsed_params.edit != null || parsed_params.copy != null);
                if (!this.showNextButton) {
                    this.requestForm = true;
                    if (this.fieldValues.Type__c !== 'Me' && this.fieldValues.Type__c != null) {
                        this.ordererForm = true;
                        this.userForm = this.fieldValues.Type__c !== 'PublicEvent';
                        this.companyForm = this.fieldValues.Type__c !== 'User';
                    }
                }
                if (!!parsed_params.copy) {
                    delete this.fieldValues.Id;
                } else {
                    this.recordId = this.fieldValues.Id;
                    let requestIds = [];
                    requestIds.push(this.fieldValues.Id);
                    this.requestIds = requestIds;
                    refreshApex(this.wiredTimesValue);
                }

                if (this.fieldValues.Type__c === 'PublicEvent') {
                    this.fieldValues.EventType__c =
                        this.fieldValues.EventType__c === 'Annet' ? 'OtherEvent' : 'SportingEvent';
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
                }
            });
        }
    }

    goToMyRequests() {
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
                }
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
