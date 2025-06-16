import LightningModal from 'lightning/modal';
import { api, track } from 'lwc';
import { columns, inDetailsColumns, mobileColumns } from './columns';
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

    showInfoAndCommentSection = true;
    showServiceAppointmentDetails = true;
    showCommentPage = false;
    spin = false;
    submittedSuccess = false;
    submittedError = false;

    isMobile = false;
    seriesRecords = [];
    @track inDetailsColumns = [];
    showTable = true;

    connectedCallback() {
        this.setupRecordDetails(this.result);
        this.setColumns();
        document.body.style.overflow = 'hidden';

        if (this.checkedServiceAppointments.length > 0) {
            this.sendInterestSeries();
        }
    }
    disconnectedCallback() {
        document.body.style.overflow = '';
    }

    setColumns() {
        if (window.screen.width > 576) {
            this.columns = columns;
            this.inDetailsColumns = inDetailsColumns;
            this.isMobile = false;
        } else {
            this.columns = mobileColumns;
            this.inDetailsColumns = inDetailsColumns;
            this.isMobile = true;
        }
    }

    sendInterestSeries() {
        if (this.isSeries) {
            this.serviceAppointmentCommentDetails = this.seriesRecords;
        }

        this.showServiceAppointmentDetails = false;
        this.showCommentPage = true;
        this.sendInterestAll = true;
        this.showSendInnButton = true;
    }

    setupRecordDetails(result) {
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
        this.showInfoAndCommentSection = false;
        this.showSendInnButton = false;
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
