import { LightningElement, wire, track, api } from 'lwc';
import getMyServiceAppointments from '@salesforce/apex/HOT_MyServiceAppointmentListController.getMyServiceAppointments';
import getServiceAppointment from '@salesforce/apex/HOT_MyServiceAppointmentListController.getServiceAppointment';
import getServiceAppointmentDetails from '@salesforce/apex/HOT_MyServiceAppointmentListController.getServiceAppointmentDetails';
import checkAccessToSA from '@salesforce/apex/HOT_MyServiceAppointmentListController.checkAccessToSA';
import getThreadFreelanceId from '@salesforce/apex/HOT_MyServiceAppointmentListController.getThreadFreelanceId';
import getThreadServiceAppointmentId from '@salesforce/apex/HOT_MyServiceAppointmentListController.getThreadServiceAppointmentId';
import getThreadInterpretersId from '@salesforce/apex/HOT_MyServiceAppointmentListController.getThreadInterpretersId';
import createThread from '@salesforce/apex/HOT_MessageHelper.createThread';
import createThreadInterpreter from '@salesforce/apex/HOT_MessageHelper.createThreadInterpreter';
import createThreadInterpreters from '@salesforce/apex/HOT_MessageHelper.createThreadInterpreters';
import getInterestedResourceDetails from '@salesforce/apex/HOT_InterestedResourcesListController.getInterestedResourceDetails';
import { NavigationMixin } from 'lightning/navigation';
import { columns, mobileColumns } from './columns';
import { defaultFilters, compare } from './filters';
import { formatRecord, formatDatetimeinterval } from 'c/datetimeFormatterNorwegianTime';
import { refreshApex } from '@salesforce/apex';
import { getDayOfWeek } from 'c/hot_commonUtils';
import { getParametersFromURL } from 'c/hot_URIDecoder';
import icons from '@salesforce/resourceUrl/ikoner';

export default class Hot_myServiceAppointmentsList_v2 extends NavigationMixin(LightningElement) {
    exitCrossIcon = icons + '/Close/Close.svg';
    @track columns = [];

    get hasResult() {
        return !this.dataLoader && this.records && this.records.length > 0;
    }

    get noServiceAppointmentsResult() {
        return !this.dataLoader && this.initialServiceAppointments.length === 0;
    }

    get noFilteredRecordsResult() {
        return (
            !this.dataLoader &&
            this.initialServiceAppointments.length > 0 &&
            this.records.length === 0 &&
            this.filters?.length > 0
        );
    }

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
        this.getParams();
        this.updateURL();
    }

    isEditButtonDisabled = false;
    isCancelButtonHidden = true;
    isEditButtonHidden = false;
    hasAccess = true;
    freelanceThreadId;

    saFreelanceThreadId;
    saThreadId;

    interestedResource;
    serviceAppointment;
    termsOfAgreement;
    isGoToThreadInterpretersButtonDisabled = false;
    isGoToThreadButtonDisabled = false;
    isGoToThreadServiceAppointmentButtonDisabled = false;

    dataLoader = true;
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
            this.records = tempRecords.map((x) => ({
                ...x,
                startAndEndDateWeekday:
                    formatDatetimeinterval(x.EarliestStartTime, x.DueDate) + ' ' + getDayOfWeek(x.EarliestStartTime)
            }));
            this.initialServiceAppointments = [...this.records];
            this.refresh();
            this.dataLoader = false;
        } else if (result.error) {
            this.dataLoader = false;
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

    closeModal() {
        this.updateURL();
        const dialog = this.template.querySelector('dialog');
        dialog.close();
    }

    showServiceAppointmentDetails() {
        const dialog = this.template.querySelector('dialog');
        dialog.showModal();
        dialog.focus();
    }

    showServiceAppointmentDetailsModal = false;
    isDetails = false;
    @track recordId;
    @track urlRedirect = false;

    openGoogleMaps() {
        window.open('https://www.google.com/maps/search/?api=1&query=' + this.address);
    }
    openAppleMaps() {
        window.open('http://maps.apple.com/?q=' + this.address);
    }

    @track serviceAppointment;
    @track interestedResource;
    @track termsOfAgreement;
    @track address;

    resetButtonFlags() {
        this.isGoToThreadInterpretersButtonDisabled = false;
        this.isGoToThreadButtonDisabled = false;
        this.isGoToThreadServiceAppointmentButtonDisabled = false;
        this.isEditButtonDisabled = false;
        this.isCancelButtonHidden = true;
    }

    isflow = false;
    goToRecordDetails(result) {
        this.isflow = false;
        this.IsEditButtonDisabled = false;
        this.isCancelButtonHidden = true;
        this.isEditButtonHidden = false;
        this.hasAccess = true;
        this.serviceAppointment = undefined;
        this.interestedResource = undefined;
        let recordId = result.detail.Id;
        this.recordId = recordId;
        this.isEditButtonHidden = false;
        this.resetButtonFlags();
        for (let serviceAppointment of this.records) {
            if (recordId === serviceAppointment.Id) {
                this.serviceAppointment = serviceAppointment;
                this.serviceAppointment.weekday = getDayOfWeek(this.serviceAppointment.EarliestStartTime);
                this.address = this.serviceAppointment.HOT_AddressFormated__c;
                this.isDetails = !!this.recordId;
                if (this.serviceAppointment.HOT_Request__r && this.serviceAppointment.HOT_Request__r.Account__r) {
                    if (
                        this.serviceAppointment.HOT_Request__r.Account__r.Name == null ||
                        this.serviceAppointment.HOT_Request__r.Account__r.Name == ''
                    ) {
                        this.isGoToThreadButtonDisabled = true;
                    } else {
                        this.isGoToThreadButtonDisabled = false;
                    }
                } else {
                    this.isGoToThreadButtonDisabled = true;
                }
                getInterestedResourceDetails({ recordId: recordId }).then((result) => {
                    this.interestedResource = result;
                    this.termsOfAgreement = this.interestedResource.HOT_TermsOfAgreement__c;
                });
                if (this.serviceAppointment.Status == 'Completed') {
                    this.isEditButtonDisabled = true;
                }
                if (this.serviceAppointment.HOT_TotalNumberOfInterpreters__c <= 1) {
                    this.isGoToThreadInterpretersButtonDisabled = true;
                }
                if (this.serviceAppointment.HOT_Request__r.IsNotNotifyAccount__c == true) {
                    this.isGoToThreadButtonDisabled = true;
                }
                this.showServiceAppointmentDetails();
            }
        }
    }
    get accountName() {
        return this.serviceAppointment?.HOT_Request__r?.Account__r?.Name ?? '';
    }

    get ownerName() {
        return this.serviceAppointment?.HOT_Request__r?.OwnerName__c ?? '';
    }

    get accountAgeGender() {
        const person = this.serviceAppointment?.HOT_Request__r?.Account__r?.CRM_Person__r;
        if (!person) return '';

        const age = person.CRM_AgeNumber__c;
        const gender = person.INT_Sex__c;

        if (age && gender) {
            return `${gender} ${age} år`;
        }
        if (age) {
            return `${age} år`;
        }
        if (gender) {
            return gender;
        }
        return '';
    }

    get accountPhoneNumber() {
        return this.serviceAppointment?.HOT_Request__r?.Account__r?.CRM_Person__r?.HOT_MobilePhone__c ?? '';
    }

    get ordererPhoneNumber() {
        return this.serviceAppointment?.HOT_Request__r?.Orderer__r?.CRM_Person__r?.HOT_MobilePhone__c ?? '';
    }
    get workType() {
        return this.serviceAppointment?.HOT_WorkTypeName__c ?? '';
    }

    get preparationTime() {
        return this.serviceAppointment?.HOT_PreparationTime__c || '';
    }

    get assignmentType() {
        return this.serviceAppointment?.HOT_AssignmentType__c ?? '';
    }

    get status() {
        return this.serviceAppointment?.Status ?? '';
    }

    get hapticCommunication() {
        const value = this.serviceAppointment?.HOT_HapticCommunication__c;
        if (value === true) return 'Ja';
        if (value === false) return 'Nei';
        return '';
    }

    get escort() {
        return this.serviceAppointment?.HOT_Escort__c ?? '';
    }

    get degreeOfHearingAndVisualImpairment() {
        return this.serviceAppointment?.HOT_DegreeOfHearingAndVisualImpairment__c ?? '';
    }

    get interpreters() {
        return this.serviceAppointment?.HOT_Interpreters__c ?? '';
    }

    get description() {
        return this.serviceAppointment?.Description ?? '';
    }

    get dispatcher() {
        return this.serviceAppointment?.HOT_Dispatcher__c ?? '';
    }

    get actualStartTime() {
        return this.serviceAppointment?.ActualStartTime ?? '';
    }

    get actualEndTime() {
        return this.serviceAppointment?.ActualEndTime ?? '';
    }
    get appointmentNumber() {
        return this.serviceAppointment?.AppointmentNumber ?? '';
    }

    get subject() {
        return this.serviceAppointment?.Subject ?? '';
    }
    get isOtherProvider() {
        return this.serviceAppointment.HOT_Request__r.IsOtherEconomicProvicer__c ? 'Ja' : 'Nei';
    }

    get startAndEndTime() {
        return (
            formatDatetimeinterval(this.serviceAppointment.SchedStartTime, this.serviceAppointment.SchedEndTime) +
            ' ' +
            getDayOfWeek(this.serviceAppointment.SchedStartTime)
        );
    }

    get address() {
        return this.serviceAppointment?.HOT_AddressFormated__c ?? '';
    }
    goToThreadFreelance() {
        this.isGoToThreadButtonDisabled = true;
        getThreadFreelanceId({ serviceAppointmentId: this.serviceAppointment.Id }).then((result) => {
            if (result != '') {
                this.saFreelanceThreadId = result;
                this.navigateToThread(this.saFreelanceThreadId);
            } else {
                createThread({ recordId: this.serviceAppointment.Id, accountId: this.serviceAppointment.accountId })
                    .then((result) => {
                        this.navigateToThread(result.Id);
                        this.saFreelanceThreadId = result;
                    })
                    .catch((error) => {});
            }
        });
    }
    goToThreadServiceAppointment() {
        this.isGoToThreadServiceAppointmentButtonDisabled = true;
        getThreadServiceAppointmentId({ serviceAppointmentId: this.serviceAppointment.Id }).then((result) => {
            if (result != '') {
                this.saThreadId = result;
                this.navigateToThread(this.saThreadId);
            } else {
                createThreadInterpreter({ recordId: this.serviceAppointment.Id })
                    .then((result) => {
                        this.saThreadId = result;
                        this.navigateToThread(result.Id);
                    })
                    .catch((error) => {});
            }
        });
    }
    goToThreadInterpreters() {
        this.isGoToThreadInterpretersButtonDisabled = true;
        getThreadInterpretersId({ serviceAppointmentId: this.serviceAppointment.Id }).then((result) => {
            if (result != '') {
                this.saFreelanceThreadId = result;
                this.navigateToThread(this.saFreelanceThreadId);
            } else {
                createThreadInterpreters({ recordId: this.serviceAppointment.Id })
                    .then((result) => {
                        this.navigateToThread(result.Id);
                        this.saFreelanceThreadId = result;
                    })
                    .catch((error) => {});
            }
        });
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

    goToRecordDetailsFromNotification(saId) {
        checkAccessToSA({ saId: saId }).then((result) => {
            if (result != false) {
                getServiceAppointmentDetails({ recordId: saId }).then((result) => {
                    this.serviceAppointment = result;
                    this.serviceAppointment.weekday = getDayOfWeek(this.serviceAppointment.EarliestStartTime);
                    this.address = this.serviceAppointment.HOT_AddressFormated__c;
                    this.isDetails = saId;
                    if (this.serviceAppointment.HOT_Request__r && this.serviceAppointment.HOT_Request__r.Account__r) {
                        if (
                            this.serviceAppointment.HOT_Request__r.Account__r.Name == null ||
                            this.serviceAppointment.HOT_Request__r.Account__r.Name == ''
                        ) {
                            this.isGoToThreadButtonDisabled = true;
                        } else {
                            this.isGoToThreadButtonDisabled = false;
                        }
                    } else {
                        this.isGoToThreadButtonDisabled = true;
                    }
                    getInterestedResourceDetails({ recordId: saId }).then((result) => {
                        this.interestedResource = result;
                        this.termsOfAgreement = this.interestedResource.HOT_TermsOfAgreement__c;
                    });
                    if (this.serviceAppointment.Status == 'Completed') {
                        this.isEditButtonDisabled = true;
                    }
                    if (this.serviceAppointment.HOT_TotalNumberOfInterpreters__c <= 1) {
                        this.isGoToThreadInterpretersButtonDisabled = true;
                    }
                    if (this.serviceAppointment.HOT_Request__r.IsNotNotifyAccount__c == true) {
                        this.isGoToThreadButtonDisabled = true;
                    }
                    this.showServiceAppointmentDetails();
                    this.urlRedirect = true;
                    this.updateURL();
                });
            } else {
                this.showServiceAppointmentDetails();
                this.hasAccess = false;
            }
        });
    }

    @api recordId;
    updateURL() {
        let baseURL = window.location.protocol + '//' + window.location.host + window.location.pathname + '?list=my';
        if (this.recordId) {
            baseURL += '&id=' + this.recordId;
        }
        window.history.pushState({ path: baseURL }, '', baseURL);
    }
    navigationId = '';
    navigationLevel = '';
    navigationBaseUrl = '';
    navigationBaseList = '';
    getParams() {
        let parsed_params = getParametersFromURL() ?? '';
        if (parsed_params.from == 'mine-varsler' && parsed_params.id != '') {
            this.navigationBaseUrl = parsed_params.from;
            this.goToRecordDetailsFromNotification(parsed_params.id);
        }
    }

    // @api goBack() {
    //     if (this.navigationBaseUrl == 'mine-varsler') {
    //         this[NavigationMixin.Navigate]({
    //             type: 'comm__namedPage',
    //             attributes: {
    //                 pageName: 'mine-varsler'
    //             },
    //             state: {}
    //         });
    //     } else {
    //         this[NavigationMixin.Navigate]({
    //             type: 'comm__namedPage',
    //             attributes: {
    //                 pageName: 'home'
    //             }
    //         });
    //     }
    // }
    filteredRecordsLength = 0;
    noFilteredRecords = false;
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
        this.noFilteredRecords = this.filteredRecordsLength === 0 && this.filters.length > 0;

        if (setRecords) {
            this.records = filteredRecords;
        }
        return this.filteredRecordsLength;
    }
    handleRefreshRecords() {
        refreshApex(this.wiredMyServiceAppointmentsResult);
    }
    changeStatus() {
        this.isflow = true;
        this.IsEditButtonDisabled = true;
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
                value: this.serviceAppointment.Id
            }
        ];
    }
    handleStatusChange(event) {
        if (event.detail.interviewStatus == 'FINISHED') {
            getServiceAppointment({
                recordId: this.serviceAppointment.Id
            }).then((data) => {
                if (data.Status == 'Completed') {
                    this.isflow = false;
                    this.isCancelButtonHidden = true;
                    this.serviceAppointment.Status = 'Dekket';
                }
                if (data.Status == 'Canceled') {
                    this.isflow = false;
                    this.isCancelButtonHidden = true;
                    this.serviceAppointment.Status = 'Avlyst';
                }
                if (data.HOT_CanceledByInterpreter__c) {
                    this.isflow = false;
                    this.isCancelButtonHidden = true;
                    this.serviceAppointment.Status = 'Tolk tar seg av';
                }
            });
            this.refreshApexCallout();
        }
    }
    //brukes til å hente nye data etter endring av statuser
    refreshApexCallout() {
        const eventToSend = new CustomEvent('refreshrecords');
        this.dispatchEvent(eventToSend);
    }
}
