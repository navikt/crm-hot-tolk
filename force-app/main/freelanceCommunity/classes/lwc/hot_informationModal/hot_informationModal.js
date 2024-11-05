import { LightningElement, api, track, wire } from 'lwc';
import LightningModal from 'lightning/modal';
import checkAccessToSA from '@salesforce/apex/HOT_MyServiceAppointmentListController.checkAccessToSA';
import getServiceAppointmentDetails from '@salesforce/apex/HOT_MyServiceAppointmentListController.getServiceAppointmentDetails';
import getInterestedResourceDetails from '@salesforce/apex/HOT_InterestedResourcesListController.getInterestedResourceDetails';
import getThreadFreelanceId from '@salesforce/apex/HOT_MyServiceAppointmentListController.getThreadFreelanceId';
import getThreadServiceAppointmentId from '@salesforce/apex/HOT_MyServiceAppointmentListController.getThreadServiceAppointmentId';
import getThreadInterpretersId from '@salesforce/apex/HOT_MyServiceAppointmentListController.getThreadInterpretersId';
import createThread from '@salesforce/apex/HOT_MessageHelper.createThread';
import createThreadInterpreter from '@salesforce/apex/HOT_MessageHelper.createThreadInterpreter';
import createThreadInterpreters from '@salesforce/apex/HOT_MessageHelper.createThreadInterpreters';
import getServiceAppointment from '@salesforce/apex/HOT_MyServiceAppointmentListController.getServiceAppointment';
import { NavigationMixin } from 'lightning/navigation';
import retractAvailability from '@salesforce/apex/HOT_WageClaimListController.retractAvailability';
import getThreadIdWC from '@salesforce/apex/HOT_WageClaimListController.getThreadId';
import getServiceResource from '@salesforce/apex/HOT_Utility.getServiceResource';
import getWageClaimDetails from '@salesforce/apex/HOT_WageClaimListController.getWageClaimDetails';

export default class Hot_informationModal extends NavigationMixin(LightningModal) {
    @api records;
    @api recordId;
    @api type;
    @api fromUrlRedirect;

    @track isAListView = true;

    // Service appointment properties
    @track saFreelanceThreadId;
    @track saThreadId;
    @track saIsflow = false;
    @track saIsEditButtonDisabled;
    @track saIsEditButtonHidden;
    @track saIsCancelButtonHidden;
    @track interestedResource;
    @track serviceAppointment;
    @track accountPhoneNumber;
    @track accountAgeGender;
    @track accountName;
    @track ownerName;
    @track ordererPhoneNumber;
    @track termsOfAgreement;
    @track isGoToThreadInterpretersButtonDisabled = false;
    @track isGoToThreadButtonDisabled = false;
    @track isGoToThreadServiceAppointmentButtonDisabled = false;

    //wageclaim

    @track wcIsNotRetractable = false;
    @track wcIsDisabledGoToThread = false;

    noCancelButton = false;
    modalHeader = 'Varsel';
    modalContent =
        'Er du sikker på at du vil fjerne tilgjengeligheten din for dette tidspunktet? Du vil da ikke ha krav på lønn.';
    @track confirmButtonLabel = 'Ja';

    @track isSADetails = false;
    @track hasAccess = false;
    @track isWCDetails = false;

    isLoading = true;
    openGoogleMaps() {
        window.open(
            'https://www.google.com/maps/search/?api=1&query=' + this.serviceAppointment.HOT_AddressFormated__c
        );
    }

    openAppleMaps() {
        window.open('http://maps.apple.com/?q=' + this.serviceAppointment.HOT_AddressFormated__c);
    }

    connectedCallback() {
        if (this.type == 'WC') {
            this.isLoading = true;
            if (this.fromUrlRedirect == true) {
                this.goToRecordDetailsWCFromId(this.recordId);
            } else if (this.fromUrlRedirect == false) {
                this.goToRecordDetailsWC(this.recordId, this.records);
            }
        } else if (this.type == 'SA') {
            if (this.fromUrlRedirect == true) {
                this.goToRecordDetailsSAFromId(this.recordId);
            } else if (this.fromUrlRedirect == false) {
                this.goToRecordDetailsSA(this.recordId, this.records);
            }
        }
    }

    handleAlertDialogClick(event) {
        if (event.detail === 'confirm' && this.noCancelButton == false) {
            this.retractAvailability();
        }
    }

    showModalRetract() {
        this.noCancelButton = false;
        this.modalHeader = 'Varsel';
        this.modalContent =
            'Er du sikker på at du vil fjerne tilgjengeligheten din for dette tidspunktet? Du vil da ikke ha krav på lønn.';
        this.confirmButtonLabel = 'Ja';
        this.showModal();
    }

    showModal() {
        this.template.querySelector('c-alertdialog').showModal();
    }

    retractAvailability() {
        try {
            retractAvailability({ recordId: this.wageClaim.Id }).then(() => {
                this.wcIsNotRetractable = true;
                this.wageClaim.Status__c = 'Tilbaketrukket tilgjengelighet';
                this.refreshApexCallout();
            });
        } catch (error) {
            alert(JSON.stringify(error));
        }
    }

    closeModal() {
        this.saIsflow = false;
        this.recordId = undefined;
        this.serviceAppointment = undefined;
        this.wageClaim = undefined;
        this.isWCDetails = false;
        this.isSADetails = false;
        if (this.isAListView) {
            this.updateURL();
        }
        this.close('closed');
    }

    @api
    goToRecordDetailsWC(woId, recordsArray) {
        this.wcIsDisabledGoToThread = false;
        this.wageClaim = undefined;
        let recordId = woId;
        this.recordId = recordId;
        this.isLoading = true;
        for (let wageClaim of recordsArray) {
            if (recordId === wageClaim.Id) {
                this.wageClaim = { ...wageClaim };
                this.wageClaim.weekday = this.getDayOfWeek(this.wageClaim.StartTime__c);
                if (this.wageClaim.Status__c == 'Åpen' || this.wageClaim.Status__c == 'Open') {
                    this.wcIsNotRetractable = false;
                } else {
                    this.wcIsNotRetractable = true;
                }
            }
        }
        this.isLoading = false;
        this.isWCDetails = true;
        this.updateURL();
    }

    @api
    goToRecordDetailsSA(saID, recordsArray) {
        let recordId = saID;
        this.serviceAppointment = undefined;
        this.interestedResource = undefined;
        this.saIsEditButtonHidden = false;
        this.saIsCancelButtonHidden = true;
        this.saIsEditButtonDisabled = false;
        this.isLoading = true;
        for (let serviceAppointment of recordsArray) {
            if (recordId === serviceAppointment.Id) {
                this.accountPhoneNumber = '';
                this.accountAgeGender = '';
                this.accountName = '';
                this.ordererPhoneNumber = '';
                this.ownerName = '';
                this.serviceAppointment = { ...serviceAppointment };
                this.serviceAppointment.weekday = this.getDayOfWeek(this.serviceAppointment.EarliestStartTime);
                this.interestedResource = serviceAppointment?.InterestedResources__r[0];
                this.termsOfAgreement = this.interestedResource.HOT_TermsOfAgreement__c;
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
                if (this.serviceAppointment.Status == 'Completed') {
                    this.saIsEditButtonDisabled = true;
                }
                if (this.serviceAppointment.HOT_TotalNumberOfInterpreters__c <= 1) {
                    this.isGoToThreadInterpretersButtonDisabled = true;
                }
                if (this.serviceAppointment.HOT_Request__r.IsNotNotifyAccount__c == true) {
                    this.isGoToThreadButtonDisabled = true;
                }
                if (
                    this.serviceAppointment &&
                    this.serviceAppointment.HOT_Request__r &&
                    this.serviceAppointment.HOT_Request__r.Account__r
                ) {
                    this.accountName = this.serviceAppointment.HOT_Request__r.Account__r.Name;
                }
                if (this.serviceAppointment && this.serviceAppointment.HOT_Request__r) {
                    this.ownerName = this.serviceAppointment.HOT_Request__r.OwnerName__c;
                }
                if (
                    this.serviceAppointment &&
                    this.serviceAppointment.HOT_Request__r &&
                    this.serviceAppointment.HOT_Request__r.Account__r &&
                    this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r
                ) {
                    if (this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r.CRM_AgeNumber__c == undefined) {
                        if (
                            this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r.HOT_Gender__c !== undefined
                        ) {
                            this.accountAgeGender =
                                this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r.HOT_Gender__c;
                        }
                    } else if (
                        this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r.HOT_Gender__c == undefined
                    ) {
                        if (
                            this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r.CRM_AgeNumber__c !==
                            undefined
                        ) {
                            this.accountAgeGender =
                                this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r.CRM_AgeNumber__c +
                                ' år';
                        }
                    } else if (
                        this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r.HOT_Gender__c !== undefined &&
                        this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r.CRM_AgeNumber__c !== undefined
                    ) {
                        this.accountAgeGender =
                            this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r.HOT_Gender__c +
                            ' ' +
                            this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r.CRM_AgeNumber__c +
                            ' år';
                    }
                    if (
                        this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r.INT_KrrMobilePhone__c !==
                        undefined
                    ) {
                        this.accountPhoneNumber =
                            this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r.INT_KrrMobilePhone__c;
                    }
                }
                if (
                    this.serviceAppointment &&
                    this.serviceAppointment.HOT_Request__r &&
                    this.serviceAppointment.HOT_Request__r.Orderer__r &&
                    this.serviceAppointment.HOT_Request__r.Orderer__r.CRM_Person__r
                ) {
                    if (
                        this.serviceAppointment.HOT_Request__r.Orderer__r.CRM_Person__r.INT_KrrMobilePhone__c !==
                        undefined
                    ) {
                        this.ordererPhoneNumber =
                            this.serviceAppointment.HOT_Request__r.Orderer__r.CRM_Person__r.INT_KrrMobilePhone__c;
                    }
                }
                this.isLoading = false;
                this.isSADetails = true;
                this.hasAccess = true;
            }
        }
        this.updateURL();
    }

    @api
    goToRecordDetailsWCFromId(recordId) {
        this.isAListView = false;
        this.isWCDetails = true;
        this.isLoading = true;
        getWageClaimDetails({ recordId: recordId }).then((result) => {
            this.wageClaim = result;
            let startTimeFormatted = new Date(this.wageClaim.StartTime__c);
            let endTimeFormatted = new Date(this.wageClaim.EndTime__c);
            this.wageClaim.StartAndEndDate =
                startTimeFormatted.getDate() +
                '.' +
                (startTimeFormatted.getMonth() + 1) +
                '.' +
                startTimeFormatted.getFullYear() +
                ', ' +
                ('0' + startTimeFormatted.getHours()).substr(-2) +
                ':' +
                ('0' + startTimeFormatted.getMinutes()).substr(-2) +
                ' - ' +
                ('0' + endTimeFormatted.getHours()).substr(-2) +
                ':' +
                ('0' + endTimeFormatted.getMinutes()).substr(-2);
            this.isWCDetails = true;
            this.isLoading = false;
        });
    }

    @api
    goToRecordDetailsSAFromId(recordId) {
        this.isSADetails = true;
        this.isAListView = false;
        if (this.type == null) {
            this.isLoading = true;
        }
        checkAccessToSA({ saId: recordId }).then((result) => {
            if (result != false) {
                getServiceAppointmentDetails({ recordId: recordId }).then((result) => {
                    this.accountPhoneNumber = '';
                    this.accountAgeGender = '';
                    this.accountName = '';
                    this.ordererPhoneNumber = '';
                    this.ownerName = '';
                    this.serviceAppointment = result;
                    let startTimeFormatted = new Date(result.EarliestStartTime);
                    let endTimeFormatted = new Date(result.DueDate);
                    this.serviceAppointment.StartAndEndDate =
                        startTimeFormatted.getDate() +
                        '.' +
                        (startTimeFormatted.getMonth() + 1) +
                        '.' +
                        startTimeFormatted.getFullYear() +
                        ', ' +
                        ('0' + startTimeFormatted.getHours()).substr(-2) +
                        ':' +
                        ('0' + startTimeFormatted.getMinutes()).substr(-2) +
                        ' - ' +
                        ('0' + endTimeFormatted.getHours()).substr(-2) +
                        ':' +
                        ('0' + endTimeFormatted.getMinutes()).substr(-2);
                    let actualstartTimeFormatted = new Date(result.ActualStartTime);
                    let actualendTimeFormatted = new Date(result.ActualEndTime);
                    this.serviceAppointment.ActualStartTime =
                        actualstartTimeFormatted.getDate() +
                        '.' +
                        (actualstartTimeFormatted.getMonth() + 1) +
                        '.' +
                        actualstartTimeFormatted.getFullYear() +
                        ' ' +
                        ('0' + actualstartTimeFormatted.getHours()).substr(-2) +
                        ':' +
                        ('0' + actualstartTimeFormatted.getMinutes()).substr(-2);
                    this.serviceAppointment.ActualEndTime =
                        actualendTimeFormatted.getDate() +
                        '.' +
                        (actualendTimeFormatted.getMonth() + 1) +
                        '.' +
                        actualendTimeFormatted.getFullYear() +
                        ' ' +
                        ('0' + actualendTimeFormatted.getHours()).substr(-2) +
                        ':' +
                        ('0' + actualendTimeFormatted.getMinutes()).substr(-2);
                    if (this.serviceAppointment.ActualStartTime.includes('NaN')) {
                        this.serviceAppointment.ActualStartTime = '';
                    }
                    if (this.serviceAppointment.ActualEndTime.includes('NaN')) {
                        this.serviceAppointment.ActualEndTime = '';
                    }
                    if (
                        this.serviceAppointment &&
                        this.serviceAppointment.HOT_Request__r &&
                        this.serviceAppointment.HOT_Request__r.Account__r
                    ) {
                        this.accountName = this.serviceAppointment.HOT_Request__r.Account__r.Name;
                    }
                    if (
                        this.serviceAppointment &&
                        this.serviceAppointment.HOT_Request__r &&
                        this.serviceAppointment.HOT_Request__r.Account__r &&
                        this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r
                    ) {
                        if (
                            this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r.CRM_AgeNumber__c ==
                            undefined
                        ) {
                            if (
                                this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r.HOT_Gender__c !==
                                undefined
                            ) {
                                this.accountAgeGender =
                                    this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r.HOT_Gender__c;
                            }
                        } else if (
                            this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r.HOT_Gender__c == undefined
                        ) {
                            if (
                                this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r.CRM_AgeNumber__c !==
                                undefined
                            ) {
                                this.accountAgeGender =
                                    this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r.CRM_AgeNumber__c +
                                    ' år';
                            }
                        } else if (
                            this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r.HOT_Gender__c !==
                                undefined &&
                            this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r.CRM_AgeNumber__c !==
                                undefined
                        ) {
                            this.accountAgeGender =
                                this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r.HOT_Gender__c +
                                ' ' +
                                this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r.CRM_AgeNumber__c +
                                ' år';
                        }
                        if (
                            this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r.INT_KrrMobilePhone__c !==
                            undefined
                        ) {
                            this.accountPhoneNumber =
                                this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r.INT_KrrMobilePhone__c;
                        }
                        if (this.serviceAppointment && this.serviceAppointment.HOT_Request__r) {
                            this.ownerName = this.serviceAppointment.HOT_Request__r.OwnerName__c;
                        }
                    }
                    if (
                        this.serviceAppointment &&
                        this.serviceAppointment.HOT_Request__r &&
                        this.serviceAppointment.HOT_Request__r.Orderer__r &&
                        this.serviceAppointment.HOT_Request__r.Orderer__r.CRM_Person__r
                    ) {
                        if (
                            this.serviceAppointment.HOT_Request__r.Orderer__r.CRM_Person__r.INT_KrrMobilePhone__c !==
                            undefined
                        ) {
                            this.ordererPhoneNumber =
                                this.serviceAppointment.HOT_Request__r.Orderer__r.CRM_Person__r.INT_KrrMobilePhone__c;
                        }
                    }
                    getInterestedResourceDetails({ recordId: recordId }).then((result) => {
                        this.interestedResource = result;
                        this.termsOfAgreement = this.interestedResource.HOT_TermsOfAgreement__c;
                    });

                    this.saIsEditButtonHidden = false;
                    this.saIsCancelButtonHidden = true;
                    this.saIsEditButtonDisabled = false;
                    this.serviceAppointment.weekday = this.getDayOfWeek(this.serviceAppointment.EarliestStartTime);
                    let duedate = new Date(this.serviceAppointment.DueDate);
                    if (this.serviceAppointment.Status == 'Completed') {
                        this.saIsEditButtonDisabled = true;
                    }
                    if (this.serviceAppointment.HOT_TotalNumberOfInterpreters__c <= 1) {
                        this.isGoToThreadInterpretersButtonDisabled = true;
                    }
                    if (this.serviceAppointment.HOT_Request__r.IsNotNotifyAccount__c == true) {
                        this.isGoToThreadButtonDisabled = true;
                    }
                    this.hasAccess = true;
                    this.isLoading = false;
                });
            } else {
                this.isLoading = false;
                this.hasAccess = false;
            }
        });
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

    updateURL() {
        let list = 'my';
        if (this.type == 'SA') {
            list = 'my';
        }
        if (this.type == 'WC') {
            list = 'wageClaim';
        }

        let baseURL =
            window.location.protocol + '//' + window.location.host + window.location.pathname + '?list=' + list;
        if (this.recordId) {
            baseURL += '&id=' + this.recordId;
        }
        window.history.pushState({ path: baseURL }, '', baseURL);
    }
    treadId;
    goToWageClaimThread() {
        this.wcIsDisabledGoToThread = true;
        getThreadIdWC({ wageClaimeId: this.wageClaim.Id }).then((result) => {
            if (result != '') {
                this.threadId = result;
                this.navigateToThread(this.threadId);
            } else {
                createThread({ recordId: this.wageClaim.Id, accountId: this.wageClaim.ServiceResource__r.AccountId })
                    .then((result) => {
                        this.navigateToThread(result.Id);
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
                this.saFreelanceThreadId = result;
                this.navigateToThread(this.saFreelanceThreadId);
            } else {
                createThreadInterpreters({ recordId: this.serviceAppointment.Id })
                    .then((result) => {
                        this.navigateToThread(result.Id);
                        this.saFreelanceThreadId = result;
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
    navigateToThread(recordId) {
        if (this.isAListView && this.isSADetails) {
            const baseUrl = '/samtale-frilans';
            const attributes = `recordId=${recordId}&from=mine-oppdrag&list=my`;
            const url = `${baseUrl}?${attributes}`;

            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: url
                }
            });
        } else if (this.isAListView && this.isWCDetails) {
            const baseUrl = '/samtale-frilans';
            const attributes = `recordId=${recordId}&from=mine-oppdrag&list=wageClaim`;
            const url = `${baseUrl}?${attributes}`;

            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: url
                }
            });
        } else {
            const baseUrl = '/samtale-frilans';
            const attributes = `recordId=${recordId}&from=kalender`;
            const url = `${baseUrl}?${attributes}`;

            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: url
                }
            });
        }
    }
    //serviceappointment endre status flow
    changeStatus() {
        this.saIsflow = true;
        this.saIsEditButtonDisabled = true;
        this.saIsCancelButtonHidden = false;
        this.isDetails = true;
        this.saIsEditButtonHidden = true;
    }
    cancelStatusFlow() {
        this.saIsflow = false;
        this.saIsEditButtonDisabled = false;
        this.saIsCancelButtonHidden = true;
        this.isDetails = true;
        this.saIsEditButtonHidden = false;
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
                    this.saIsflow = false;
                    this.saIsCancelButtonHidden = true;
                    this.serviceAppointment.Status = 'Dekket';
                }
                if (data.Status == 'Canceled') {
                    this.saIsflow = false;
                    this.saIsCancelButtonHidden = true;
                    this.serviceAppointment.Status = 'Avlyst';
                }
                if (data.HOT_CanceledByInterpreter__c) {
                    this.saIsflow = false;
                    this.saIsCancelButtonHidden = true;
                    this.serviceAppointment.Status = 'Avlyst';
                }
            });
            this.refreshApexCallout();
        }
    }
    handleKeyDown(event) {
        if (event.code == 'Escape') {
            this.closeModal();
        }
    }
    //brukes til å hente nye data etter endring av statuser
    refreshApexCallout() {
        const eventToSend = new CustomEvent('refreshrecords');
        this.dispatchEvent(eventToSend);
    }

    @track fileUploadMessage;
    handleUploadFinished(event) {
        const uploadedFiles = event.detail.files;
        if (uploadedFiles.length > 0) {
            this.fileUploadMessage = 'Filen(e) ble lastet opp. Se filen i listen over vedlegg ovenfor.';
            this.template.querySelector('c-record-files-with-sharing').refreshContentDocuments();
        } else {
            this.fileUploadMessage = '';
        }
    }
}
