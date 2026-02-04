import { LightningElement, wire, api } from 'lwc';
import getMyServiceAppointments from '@salesforce/apex/HOT_MyServiceAppointmentListController.getMyServiceAppointments';
import getMyLateCancelledServiceAppointments from '@salesforce/apex/HOT_LateCancellationListController.getLateCancellationsForUser';
import { columns, mobileColumns } from './columns';
import { formatRecord, formatDatetimeinterval } from 'c/datetimeFormatterNorwegianTime';
import { refreshApex } from '@salesforce/apex';
import { getDayOfWeek } from 'c/hot_commonUtils';
import { defaultFilters, compare } from './filters';
import getInterestedResourceDetails from '@salesforce/apex/HOT_InterestedResourcesListController.getInterestedResourceDetails';
import icons from '@salesforce/resourceUrl/ikoner';

export default class Hot_lateCancellationList extends LightningElement {
    records = [];
    columns = [];
    filters = [];
    initialServiceAppointments = [];
    hasAccess = true;
    dataLoader = true;
    isDetails = false;
    exitCrossIcon = icons + '/Close/Close.svg';

    @api recordId;

    datetimeFields = [
        { name: 'StartAndEndDate', type: 'datetimeinterval', start: 'EarliestStartTime', end: 'DueDate' }
    ];

    connectedCallback() {
        refreshApex(this.wiredMyServiceAppointmentsResult);
        this.setColumns();
        this.updateURL();
    }

    setColumns() {
        if (window.screen.width > 576) {
            this.columns = columns;
        } else {
            this.columns = mobileColumns;
        }
    }

    wiredMyServiceAppointmentsResult;
    @wire(getMyLateCancelledServiceAppointments)
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
            console.log('Late cancellation records:', this.records);
        } else if (result.error) {
            this.dataLoader = false;
            this.error = result.error;
            this.allMyServiceAppointmentsWired = undefined;
        }
    }

    refresh() {
        let filterFromSessionStorage = JSON.parse(sessionStorage.getItem('lateCancellationSessionFilter'));
        this.filters = filterFromSessionStorage === null ? defaultFilters() : filterFromSessionStorage;
        this.sendRecords();
        this.sendFilters();
        this.applyFilter({ detail: { filterArray: this.filters, setRecords: true } });
    }

    sendFilters() {
        const eventToSend = new CustomEvent('sendfilters', { detail: this.filters });
        this.dispatchEvent(eventToSend);
    }
    sendRecords() {
        const eventToSend = new CustomEvent('sendrecords', { detail: this.initialServiceAppointments });
        this.dispatchEvent(eventToSend);
    }

    filteredRecordsLength = 0;
    noFilteredRecords = false;
    @api
    applyFilter(event) {
        let setRecords = event.detail.setRecords;
        this.filters = event.detail.filterArray;
        sessionStorage.setItem('lateCancellationSessionFilter', JSON.stringify(this.filters));
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

    serviceAppointment;
    interestedResource;
    goToRecordDetails(result) {
        this.serviceAppointment = undefined;
        this.interestedResource = undefined;
        let recordId = result.detail.Id;
        this.recordId = recordId;
        for (let serviceAppointment of this.records) {
            if (recordId === serviceAppointment.Id) {
                this.serviceAppointment = serviceAppointment;
                this.serviceAppointment.weekday = getDayOfWeek(this.serviceAppointment.EarliestStartTime);
                this.isDetails = !!this.recordId;
                this.showServiceAppointmentDetails();
                getInterestedResourceDetails({ recordId: recordId }).then((result) => {
                    this.interestedResource = result;
                });
            }
        }
    }

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

    sendDetail() {
        const eventToSend = new CustomEvent('senddetail', { detail: this.isDetails });
        this.dispatchEvent(eventToSend);
    }

    updateURL() {
        let baseURL =
            window.location.protocol +
            '//' +
            window.location.host +
            window.location.pathname +
            '?list=lateCancellation';
        if (this.recordId) {
            baseURL += '&id=' + this.recordId;
        }
        window.history.pushState({ path: baseURL }, '', baseURL);
    }
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

    get appointmentNumber() {
        return this.serviceAppointment?.AppointmentNumber ?? '';
    }

    get subject() {
        return this.serviceAppointment?.Subject ?? '';
    }

    get startAndEndTime() {
        return (
            formatDatetimeinterval(this.serviceAppointment.SchedStartTime, this.serviceAppointment.SchedEndTime) +
            ' ' +
            getDayOfWeek(this.serviceAppointment.SchedStartTime)
        );
    }

    get appointmentCity() {
        return this.serviceAppointment?.HOT_InterpretationPostalCity__c ?? '';
    }

    get workType() {
        return this.serviceAppointment?.HOT_WorkTypeName__c ?? '';
    }

    get assignmentType() {
        return this.serviceAppointment?.HOT_AssignmentType__c ?? '';
    }

    get ownerName() {
        return this.serviceAppointment?.HOT_Request__r?.OwnerName__c ?? '';
    }

    get status() {
        return this.serviceAppointment?.Status ?? '';
    }

    get degreeOfHearingAndVisualImpairment() {
        return this.serviceAppointment?.HOT_DegreeOfHearingAndVisualImpairment__c ?? '';
    }

    get canceledDate() {
        const dateVal = this.interestedResource?.WorkOrderCanceledDate__c;
        if (!dateVal) {
            return '';
        }

        const d = new Date(dateVal);
        return (
            d.getDate() +
            '.' +
            (d.getMonth() + 1) +
            '.' +
            d.getFullYear() +
            ', ' +
            ('0' + d.getHours()).slice(-2) +
            ':' +
            ('0' + d.getMinutes()).slice(-2)
        );
    }
}
