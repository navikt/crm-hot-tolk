import { LightningElement, api, track } from 'lwc';
import checkAccessToSA from '@salesforce/apex/HOT_MyServiceAppointmentListController.checkAccessToSA';
import getServiceAppointmentDetails from '@salesforce/apex/HOT_MyServiceAppointmentListController.getServiceAppointmentDetails';
import getInterestedResourceDetails from '@salesforce/apex/HOT_InterestedResourcesListController.getInterestedResourceDetails';
import getThreadFreelanceId from '@salesforce/apex/HOT_MyServiceAppointmentListController.getThreadFreelanceId';
import getThreadServiceAppointmentId from '@salesforce/apex/HOT_MyServiceAppointmentListController.getThreadServiceAppointmentId';
import getThreadInterpretersId from '@salesforce/apex/HOT_MyServiceAppointmentListController.getThreadInterpretersId';
import createThread from '@salesforce/apex/HOT_MessageHelper.createThread';
import createThreadInterpreter from '@salesforce/apex/HOT_MessageHelper.createThreadInterpreter';
import createThreadInterpreters from '@salesforce/apex/HOT_MessageHelper.createThreadInterpreters';
import { NavigationMixin } from 'lightning/navigation';

export default class Hot_informationModal extends NavigationMixin(LightningElement) {
    @api records;
    @api recordId;
    @api type;
    @api showDetails = false;
    @api fromUrlRedirect;

    @track freelanceThreadId;
    @track saThreadId;
    @track isflow = false;

    //serviceappointment
    @track isEditButtonDisabled;
    @track isEditButtonHidden;
    @track isCancelButtonHidden;

    @track interestedResource;
    @track serviceAppointment;
    @track accountPhoneNumber;
    @track accountAgeGender;
    @track accountName;
    @track ownerName;
    @track ordererPhoneNumber;
    @track address;
    @track termsOfAgreement;

    @track isGoToThreadInterpretersButtonDisabled = false;
    @track isGoToThreadButtonDisabled = false;
    @track isGoToThreadServiceAppointmentButtonDisabled = false;

    @track isSADetails = false;
    @track hasAccess = false;

    openGoogleMaps() {
        window.open('https://www.google.com/maps/search/?api=1&query=' + this.address);
    }
    openAppleMaps() {
        window.open('http://maps.apple.com/?q=' + this.address);
    }
    connectedCallback() {
        console.log('kjører denne?');
        if (this.fromUrlRedirect == true && this.showDetails == true) {
            this.goToRecordDetailsSAFromId(this.recordId);
        }
    }

    closeModal() {
        this.recordId = undefined;
        this.updateURL();
        // this.template.querySelector('.details').classList.add('hidden');
        const dialog = this.template.querySelector('dialog.details');
        dialog.close();
    }
    @api
    showModalPopup() {
        this.template.querySelector('.details').classList.remove('hidden');
    }
    @api
    goToRecordDetailsSA(saID, recordsArray) {
        const dialog = this.template.querySelector('dialog.details');
        dialog.showModal();
        dialog.focus();
        let today = new Date();
        let recordId = saID;
        this.serviceAppointment = undefined;
        this.interestedResource = undefined;
        this.isEditButtonHidden = false;
        this.isCancelButtonHidden = true;
        this.isEditButtonDisabled = false;
        for (let serviceAppointment of recordsArray) {
            console.log(serviceAppointment.Id);
            if (recordId === serviceAppointment.Id) {
                this.accountPhoneNumber = '';
                this.accountAgeGender = '';
                this.accountName = '';
                this.ordererPhoneNumber = '';
                this.ownerName = '';
                this.serviceAppointment = serviceAppointment;
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
                const dialog = this.template.querySelector('dialog.details');
                dialog.showModal();
                dialog.focus();
                this.showDetails = true;
                this.isSADetails = true;
                this.hasAccess = true;
            }
        }
        //this.updateURL();
    }
    goToRecordDetailsSAFromId(recordId) {
        this.isSADetails = true;
        this.hasAccess = true;
        getServiceAppointmentDetails({ recordId: recordId }).then((result) => {
            this.serviceAppointment = result;
            console.log(this.serviceAppointment.AppointmentNumber);
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
                if (this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r.CRM_AgeNumber__c == undefined) {
                    if (this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r.HOT_Gender__c !== undefined) {
                        this.accountAgeGender =
                            this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r.HOT_Gender__c;
                    }
                } else if (this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r.HOT_Gender__c == undefined) {
                    if (
                        this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r.CRM_AgeNumber__c !== undefined
                    ) {
                        this.accountAgeGender =
                            this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r.CRM_AgeNumber__c + ' år';
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
                    this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r.INT_KrrMobilePhone__c !== undefined
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
                    this.serviceAppointment.HOT_Request__r.Orderer__r.CRM_Person__r.INT_KrrMobilePhone__c !== undefined
                ) {
                    this.ordererPhoneNumber =
                        this.serviceAppointment.HOT_Request__r.Orderer__r.CRM_Person__r.INT_KrrMobilePhone__c;
                }
            }
            getInterestedResourceDetails({ recordId: recordId }).then((result) => {
                this.interestedResource = result;
                this.termsOfAgreement = this.interestedResource.HOT_TermsOfAgreement__c;
            });

            this.isEditButtonHidden = false;
            this.isCancelButtonHidden = true;
            this.isEditButtonDisabled = false;
            this.serviceAppointment.weekday = this.getDayOfWeek(this.serviceAppointment.EarliestStartTime);
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
            const dialog = this.template.querySelector('dialog.details');
            dialog.showModal();
            dialog.focus();
            //this.updateURL();
        });
        //} else {
        // this.hasAccess = false;
        //  this.template.querySelector('.details').classList.remove('hidden');
        // this.template.querySelector('.details').focus();
        // }
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
        let baseURL = window.location.protocol + '//' + window.location.host + window.location.pathname + '?list=my';
        if (this.recordId) {
            baseURL += '&id=' + this.recordId;
        }
        window.history.pushState({ path: baseURL }, '', baseURL);
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
        console.log('trykker');
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
                        //this.showModal();
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
                        //this.showModal();
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
                        //this.showModal();
                    });
            }
        });
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
                    this.serviceAppointment.Status = 'Avlyst';
                }
            });
            refreshApex(this.wiredMyServiceAppointmentsResult);
        }
    }
    handleKeyDown(event) {
        if (event.code == 'Escape') {
            this.closeModal();
        }
    }
}
