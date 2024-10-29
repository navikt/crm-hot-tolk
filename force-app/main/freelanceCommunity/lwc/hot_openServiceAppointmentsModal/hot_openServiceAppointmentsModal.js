import LightningModal from 'lightning/modal';
import { api, track } from 'lwc';
import createInterestedResources from '@salesforce/apex/HOT_OpenServiceAppointmentListController.createInterestedResources';

export default class Hot_openServiceAppointmentsModal extends LightningModal {
    @api serviceAppointmentCommentDetails = [];
    @api checkedServiceAppointments = [];
    @api serviceAppointment;
    @api result;
    @api isSeries;
    @api isDetails;
    @api sendInterestAll = false;
    @api records = [];
    @track errorMessage = '';
    @track spin = false;
    @track submittedSuccess = false;
    @track submittedError = false;

    isMobile = false;
    seriesRecords = [];
    @track inDetailsColumns = [];
    showTable = true;

    isServiceAppointmentCommentDetails = false;

    connectedCallback() {
        this.goToRecordDetails(this.result);
        console.log('Modal connectedCallback result:', this.result);
        console.log('checkedServiceAppointments', this.checkedServiceAppointments);
        console.log('checkedServiceAppointments length', this.checkedServiceAppointments.length);

        this.isServiceAppointmentCommentDetails = this.serviceAppointmentCommentDetails.length > 0;
        console.log('isServiceAppointmentCommentDetails:', this.isServiceAppointmentCommentDetails);
        console.log('serviceAppointmentCommentDetails:', this.serviceAppointmentCommentDetails);
        console.log('checkedServiceAppointments:', this.checkedServiceAppointments);

        if (this.checkedServiceAppointments.length > 0) {
            this.sendInterestSeries();
        } else {
        }
    }

    // State variables for conditional rendering
    showServiceAppointmentDetails = true;
    showCommentPage = false;
    showSubmittedError = false;
    showSubmittedLoading = false;
    showSubmittedTrue = false;
    showCommentDetails = false;
    showSendInnButton = false;

    sendInterestSeries() {
        this.showServiceAppointmentDetails = false;
        this.hideSubmitIndicators();
        this.showCommentSection();

        this.sendInterestAll = true;
        this.showCommentPageMethod();
    }

    showCommentPageMethod() {
        this.showCommentPage = true;
    }

    hideSubmitIndicators() {
        this.showSubmittedError = false;
        this.showSubmittedLoading = false;
        this.showSubmittedTrue = false;
    }

    showCommentSection() {
        this.showCommentDetails = true;
        this.showSendInnButton = true;
    }

    goToRecordDetails(result) {
        this.serviceAppointment = undefined;
        this.seriesRecords = [];
        let recordId = result.detail ? result.detail.Id : result.Id;
        this.recordId = recordId;
        this.isDetails = !!this.recordId;

        for (let serviceAppointment of this.records) {
            if (recordId === serviceAppointment.Id) {
                this.serviceAppointment = { ...serviceAppointment };
                this.isSeries = this.serviceAppointment.HOT_IsSerieoppdrag__c;
                this.serviceAppointment.weekday = this.getDayOfWeek(this.serviceAppointment.EarliestStartTime);
            }
        }

        for (let serviceAppointment of this.records) {
            if (this.serviceAppointment?.HOT_Request__c === serviceAppointment?.HOT_Request__c) {
                this.seriesRecords.push(serviceAppointment);
            }
        }

        this.isSeries = this.seriesRecords.length > 1;
    }

    getDayOfWeek(date) {
        var jsDate = new Date(date);
        var dayOfWeek = jsDate.getDay();
        var days = ['Søndag', 'Mandag', 'Tirsdag', 'Onsdag', 'Torsdag', 'Fredag', 'Lørdag'];
        return days[dayOfWeek] || '';
    }

    registerInterest() {
        this.spin = true;
        this.submittedSuccess = false;
        this.submittedError = false;

        // Gather comments
        const comments = [];
        this.template.querySelectorAll('.comment-field').forEach((element) => {
            comments.push(element.value);
        });

        const serviceAppointmentIds = this.serviceAppointmentCommentDetails.map((item) => item.Id);

        createInterestedResources({
            serviceAppointmentIds,
            comments
        })
            .then(() => {
                this.spin = false;
                this.submittedSuccess = true;
            })
            .catch((error) => {
                this.spin = false;
                this.errorMessage = error.body ? error.body.message : error.message;
                this.submittedError = true;
            });
    }

    closeModal() {
        this.close({
            success: this.submittedSuccess,
            error: this.submittedError
        });
    }
}
