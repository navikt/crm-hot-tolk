import { LightningElement, wire, track, api } from 'lwc';
import getMyServiceAppointments from '@salesforce/apex/HOT_MyServiceAppointmentListController.getMyServiceAppointments';
import getServiceAppointment from '@salesforce/apex/HOT_MyServiceAppointmentListController.getServiceAppointment';
import getOrdererInformation from '@salesforce/apex/HOT_MyServiceAppointmentListController.getOrdererInformation';
import getAccountPhonenumber from '@salesforce/apex/HOT_MyServiceAppointmentListController.getAccountPhonenumber';
import getAccountName from '@salesforce/apex/HOT_MyServiceAppointmentListController.getAccountName';
import getOwnerName from '@salesforce/apex/HOT_MyServiceAppointmentListController.getOwnerName';
import getServiceResource from '@salesforce/apex/HOT_Utility.getServiceResource';
import getThreadFreelanceId from '@salesforce/apex/HOT_MyServiceAppointmentListController.getThreadFreelanceId';
import getThreadServiceAppointmentId from '@salesforce/apex/HOT_MyServiceAppointmentListController.getThreadServiceAppointmentId';
import getThreadInterpretersId from '@salesforce/apex/HOT_MyServiceAppointmentListController.getThreadInterpretersId';
import createThread from '@salesforce/apex/HOT_MessageHelper.createThread';
import createThreadInterpreter from '@salesforce/apex/HOT_MessageHelper.createThreadInterpreter';
import createThreadInterpreters from '@salesforce/apex/HOT_MessageHelper.createThreadInterpreters';
import { NavigationMixin } from 'lightning/navigation';
import { columns, mobileColumns } from './columns';
import { defaultFilters, compare } from './filters';
import { formatRecord } from 'c/datetimeFormatter';
import { refreshApex } from '@salesforce/apex';

export default class Hot_myServiceAppointments extends NavigationMixin(LightningElement) {
    @track columns = [];
    @track isEditButtonDisabled = false;
    @track isCancelButtonHidden = true;
    @track isEditButtonHidden = false;
    freelanceThreadId;
    isGoToThreadButtonDisabled = false;
    isGoToThreadServiceAppointmentButtonDisabled = false;
    isGoToThreadInterpretersButtonDisabled = false;
    setColumns() {
        if (window.screen.width > 576) {
            this.columns = columns;
        } else {
            this.columns = mobileColumns;
        }
    }

    sendFilters() {
        const eventToSend = new CustomEvent('sendfilters', { detail: this.filters });
        this.dispatchEvent(eventToSend);
    }
    sendRecords() {
        const eventToSend = new CustomEvent('sendrecords', { detail: this.initialServiceAppointments });
        this.dispatchEvent(eventToSend);
    }
    sendDetail() {
        const eventToSend = new CustomEvent('senddetail', { detail: this.isDetails });
        this.dispatchEvent(eventToSend);
    }

    setPreviousFiltersOnRefresh() {
        if (sessionStorage.getItem('myfilters')) {
            this.applyFilter({
                detail: { filterArray: JSON.parse(sessionStorage.getItem('myfilters')), setRecords: true }
            });
            sessionStorage.removeItem('myfilters');
        }
        this.sendFilters();
    }

    disconnectedCallback() {
        // Going back with browser back or back button on mouse forces page refresh and a disconnect
        // Save filters on disconnect to exist only within the current browser tab
        sessionStorage.setItem('myfilters', JSON.stringify(this.filters));
    }

    renderedCallback() {
        this.setPreviousFiltersOnRefresh();
    }

    @track filters = [];
    connectedCallback() {
        refreshApex(this.wiredMyServiceAppointmentsResult);
        this.setColumns();
        this.updateURL();
    }
    @track serviceResource;
    @wire(getServiceResource)
    wiredServiceresource(result) {
        if (result.data) {
            this.serviceResource = result.data;
        }
    }

    noServiceAppointments = false;
    initialServiceAppointments = [];
    @track records = [];
    @track allMyServiceAppointmentsWired = [];
    wiredMyServiceAppointmentsResult;
    @wire(getMyServiceAppointments)
    wiredMyServiceAppointments(result) {
        this.wiredMyServiceAppointmentsResult = result;
        if (result.data) {
            let tempRecords = [];
            for (let record of result.data) {
                tempRecords.push(formatRecord(Object.assign({}, record), this.datetimeFields));
            }
            this.allMyServiceAppointmentsWired = tempRecords;
            this.noServiceAppointments = this.allMyServiceAppointmentsWired.length === 0;
            this.error = undefined;
            this.records = tempRecords;
            this.initialServiceAppointments = [...this.records];
            this.refresh();
        } else if (result.error) {
            this.error = result.error;
            this.allMyServiceAppointmentsWired = undefined;
        }
    }

    refresh() {
        let filterFromSessionStorage = JSON.parse(sessionStorage.getItem('mySessionFilter'));
        this.filters = filterFromSessionStorage === null ? defaultFilters() : filterFromSessionStorage;
        this.sendRecords();
        this.sendFilters();
        this.applyFilter({ detail: { filterArray: this.filters, setRecords: true } });
    }

    datetimeFields = [
        { name: 'StartAndEndDate', type: 'datetimeinterval', start: 'EarliestStartTime', end: 'DueDate' },
        { name: 'ActualStartTime', type: 'datetime' },
        { name: 'ActualEndTime', type: 'datetime' },
        { name: 'HOT_DeadlineDate__c', type: 'date' },
        { name: 'HOT_ReleaseDate__c', type: 'date' }
    ];
    openGoogleMaps() {
        window.open('https://www.google.com/maps/search/?api=1&query=' + this.address);
    }
    openAppleMaps() {
        window.open('http://maps.apple.com/?q=' + this.address);
    }
    getDayOfWeek(date) {
        var jsDate = new Date(date);
        var dayOfWeek = jsDate.getDay();
        var dayOfWeekString;
        switch (dayOfWeek) {
            case 0:
                dayOfWeekString = 'Søndag';
                break;
            case 1:
                dayOfWeekString = 'Mandag';
                break;
            case 2:
                dayOfWeekString = 'Tirsdag';
                break;
            case 3:
                dayOfWeekString = 'Onsdag';
                break;
            case 4:
                dayOfWeekString = 'Torsdag';
                break;
            case 5:
                dayOfWeekString = 'Fredag';
                break;
            case 6:
                dayOfWeekString = 'Lørdag';
                break;
            default:
                dayOfWeekString = '';
        }
        return dayOfWeekString;
    }
    @track serviceAppointment;
    @track interestedResource;
    @track ordererPhoneNumber;
    @track accountPhoneNumber;
    @track accountName;
    @track ownerName;
    @track address;

    isDetails = false;
    isflow = false;
    isSeries = false;
    showTable = true;
    goToRecordDetails(result) {
        getOrdererInformation({ serviceAppointmentId: result.detail.Id })
            .then((phonenumber) => {
                this.ordererPhoneNumber = phonenumber;
            })
            .catch((error) => {
                this.ordererPhoneNumber = '';
            });
        getAccountPhonenumber({ serviceAppointmentId: result.detail.Id })
            .then((phonenumber) => {
                this.accountPhoneNumber = phonenumber;
            })
            .catch((error) => {
                this.accountPhoneNumber = '';
            });
        getAccountName({ serviceAppointmentId: result.detail.Id })
            .then((name) => {
                this.accountName = name;
                if (this.accountName == null || this.accountName == '') {
                    this.isGoToThreadButtonDisabled = true;
                } else {
                    this.isGoToThreadButtonDisabled = false;
                }
            })
            .catch((error) => {
                this.accountName = '';
            });
        getOwnerName({ serviceAppointmentId: result.detail.Id })
            .then((owner) => {
                this.ownerName = owner;
            })
            .catch((error) => {
                this.ownerName = '';
            });
        this.template.querySelector('.serviceAppointmentDetails').classList.remove('hidden');
        this.template.querySelector('.serviceAppointmentDetails').focus();
        let today = new Date();
        this.serviceAppointment = undefined;
        this.interestedResource = undefined;
        let recordId = result.detail.Id;
        this.recordId = recordId;
        this.isDetails = !!this.recordId;
        this.isEditButtonHidden = false;
        this.isCancelButtonHidden = true;
        this.isEditButtonDisabled = false;
        for (let serviceAppointment of this.records) {
            if (recordId === serviceAppointment.Id) {
                this.serviceAppointment = serviceAppointment;
                this.serviceAppointment.weekday = this.getDayOfWeek(this.serviceAppointment.EarliestStartTime);
                this.interestedResource = serviceAppointment?.InterestedResources__r[0];
                this.address = serviceAppointment.HOT_AddressFormated__c;

                let duedate = new Date(this.serviceAppointment.DueDate);
                if (this.serviceAppointment.Status == 'Completed') {
                    this.isEditButtonDisabled = true;
                }
                if (this.serviceAppointment.HOT_TotalNumberOfInterpreters__c <= 1) {
                    this.isGoToThreadInterpretersButtonDisabled = true;
                }
                if (this.serviceAppointment.HOT_Request__r.IsNotNotifyAccount__c == true) {
                    this.isGoToThreadButtonDisabled = true;
                }
            }
        }
        this.updateURL();
        //this.sendDetail();
    }

    @api recordId;
    updateURL() {
        let baseURL = window.location.protocol + '//' + window.location.host + window.location.pathname + '?list=my';
        if (this.recordId) {
            baseURL += '&id=' + this.recordId;
        }
        window.history.pushState({ path: baseURL }, '', baseURL);
    }

    @api goBack() {
        let recordIdToReturn = this.recordId;
        this.recordId = undefined;
        this.isDetails = false;
        this.showTable = true;
        this.isflow = false;
        this.isEditButtonDisabled = false;
        this.sendDetail();
        return { id: recordIdToReturn, tab: 'my' };
    }
    filteredRecordsLength = 0;
    @api
    applyFilter(event) {
        let setRecords = event.detail.setRecords;
        this.filters = event.detail.filterArray;
        sessionStorage.setItem('mySessionFilter', JSON.stringify(this.filters));
        let filteredRecords = [];
        let records = this.initialServiceAppointments;
        for (let record of records) {
            let includeRecord = true;
            for (let filter of this.filters) {
                includeRecord *= compare(filter, record);
            }
            if (includeRecord) {
                filteredRecords.push(record);
            }
        }
        this.filteredRecordsLength = filteredRecords.length;

        if (setRecords) {
            this.records = filteredRecords;
        }
        return this.filteredRecordsLength;
    }
    changeStatus() {
        this.isflow = true;
        this.isEditButtonDisabled = true;
        this.isCancelButtonHidden = false;
        this.isDetails = true;
        this.isEditButtonHidden = true;
    }
    cancelStatusFlow() {
        this.isflow = false;
        this.isEditButtonDisabled = false;
        this.isCancelButtonHidden = true;
        this.isDetails = true;
        this.isEditButtonHidden = false;
    }
    get flowVariables() {
        return [
            {
                name: 'recordId',
                type: 'String',
                value: this.recordId
            }
        ];
    }
    navigateToThread(recordId) {
        const baseUrl = '/samtale-frilans';
        const attributes = `recordId=${recordId}&from=mine-oppdrag&list=my`;
        const url = `${baseUrl}?${attributes}`;

        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: url
            }
        });
    }

    goToThreadFreelance() {
        this.isGoToThreadButtonDisabled = true;
        getThreadFreelanceId({ serviceAppointmentId: this.serviceAppointment.Id }).then((result) => {
            if (result != '') {
                this.freelanceThreadId = result;
                this.navigateToThread(this.freelanceThreadId);
            } else {
                createThread({ recordId: this.serviceAppointment.Id, accountId: this.serviceAppointment.accountId })
                    .then((result) => {
                        this.navigateToThread(result.Id);
                        this.freelanceThreadId = result;
                    })
                    .catch((error) => {
                        this.modalHeader = 'Noe gikk galt';
                        this.modalContent = 'Kunne ikke åpne samtale. Feilmelding: ' + error;
                        this.noCancelButton = true;
                        this.showModal();
                    });
            }
        });
    }
    goToThreadServiceAppointment() {
        console.log('yayy');
        this.isGoToThreadServiceAppointmentButtonDisabled = true;
        getThreadServiceAppointmentId({ serviceAppointmentId: this.serviceAppointment.Id }).then((result) => {
            if (result != '') {
                this.saThreadId = result;
                this.navigateToThread(this.saThreadId);
            } else {
                createThreadInterpreter({ recordId: this.serviceAppointment.Id })
                    .then((result) => {
                        this.navigateToThread(result.Id);
                        this.saThreadId = result;
                    })
                    .catch((error) => {
                        this.modalHeader = 'Noe gikk galt';
                        this.modalContent = 'Kunne ikke åpne samtale. Feilmelding: ' + error;
                        this.noCancelButton = true;
                        this.showModal();
                    });
            }
        });
    }
    goToThreadInterpreters() {
        this.isGoToThreadInterpretersButtonDisabled = true;
        getThreadInterpretersId({ serviceAppointmentId: this.serviceAppointment.Id }).then((result) => {
            if (result != '') {
                this.freelanceThreadId = result;
                this.navigateToThread(this.freelanceThreadId);
                console.log('finnes');
            } else {
                console.log('finnes ingen');
                createThreadInterpreters({ recordId: this.serviceAppointment.Id })
                    .then((result) => {
                        this.navigateToThread(result.Id);
                        this.freelanceThreadId = result;
                    })
                    .catch((error) => {
                        this.modalHeader = 'Noe gikk galt';
                        this.modalContent = 'Kunne ikke åpne samtale. Feilmelding: ' + error;
                        this.noCancelButton = true;
                        this.showModal();
                    });
            }
        });
    }

    closeModal() {
        this.template.querySelector('.serviceAppointmentDetails').classList.add('hidden');
        this.recordId = undefined;
        this.updateURL();
        this.isGoToThreadButtonDisabled = false;
        this.isGoToThreadServiceAppointmentButtonDisabled = false;
        this.isGoToThreadInterpretersButtonDisabled = false;
    }
    handleStatusChange(event) {
        console.log('handleStatusChange', event.detail);
        if (event.detail.interviewStatus == 'FINISHED') {
            getServiceAppointment({
                recordId: this.recordId
            }).then((data) => {
                console.log(data.Status);
                if (data.Status == 'Completed') {
                    this.isflow = false;
                    this.isCancelButtonHidden = true;
                    this.serviceAppointment.Status = 'Completed';
                }
                if (data.Status == 'Canceled') {
                    this.isflow = false;
                    this.isCancelButtonHidden = true;
                    this.serviceAppointment.Status = 'Canceled';
                }
                if (data.HOT_CanceledByInterpreter__c) {
                    this.isflow = false;
                    this.isCancelButtonHidden = true;
                    this.serviceAppointment.Status = 'None';
                }
            });
            refreshApex(this.wiredMyServiceAppointmentsResult);
        }
    }
}
