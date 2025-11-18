import { LightningElement, wire, api } from 'lwc';
import getWantedServiceAppointments from '@salesforce/apex/HOT_wantedSRListController.getWantedServiceAppointments';
import updateInterestedResource from '@salesforce/apex/HOT_wantedSRListController.updateInterestedResource';
import updateInterestedResourceChecked from '@salesforce/apex/HOT_wantedSRListController.updateInterestedResourceChecked';
import declineInterestedResourceChecked from '@salesforce/apex/HOT_wantedSRListController.declineInterestedResourceChecked';
import declineInterestedResource from '@salesforce/apex/HOT_wantedSRListController.declineInterestedResource';
import getServiceResource from '@salesforce/apex/HOT_Utility.getServiceResource';
import { columns, inDetailsColumns, mobileColumns } from './columns';
import { refreshApex } from '@salesforce/apex';
import { defaultFilters, compare, setDefaultFilters } from './filters';
import { formatRecord, formatDatetimeinterval } from 'c/datetimeFormatterNorwegianTime';
import { getDayOfWeek } from 'c/hot_commonUtils';
import icons from '@salesforce/resourceUrl/ikoner';

export default class Hot_wantedServiceAppointmentsList extends LightningElement {
    exitCrossIcon = icons + '/Close/Close.svg';
    columns = [];
    inDetailsColumns = [];
    processMessage;
    processMessageResult;
    isMobile;
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
    iconByValue = {
        false: {
            icon: '',
            fill: '',
            ariaLabel: ''
        },
        true: {
            icon: 'WarningFilled',
            fill: 'Red',
            ariaLabel: 'Høyt prioritert'
        }
    };
    dataLoader = true;
    get hasResult() {
        return !this.dataLoader && this.records && this.records.length > 0;
    }

    get noServiceAppointmentsResult() {
        return !this.dataLoader && this.initialServiceAppointments.length === 0;
    }

    sendRecords() {
        const eventToSend = new CustomEvent('sendrecords', { detail: this.initialServiceAppointments });
        this.dispatchEvent(eventToSend);
    }
    sendDetail() {
        const eventToSend = new CustomEvent('senddetail', { detail: this.isDetails });
        this.dispatchEvent(eventToSend);
    }
    showSendInterestOrDecline = false;
    sendCheckedRows() {
        this.showSendInterestOrDecline = this.checkedServiceAppointments.length > 0;
        this.sendInterestButtonLabel = 'Meld interesse til ' + this.checkedServiceAppointments.length + ' oppdrag';
        this.declineInterestButtonLabel = 'Avslå interesse til ' + this.checkedServiceAppointments.length + ' oppdrag';
        const eventToSend = new CustomEvent('sendcheckedrows', { detail: this.checkedServiceAppointments });
        this.dispatchEvent(eventToSend);
    }
    sendInterestButtonLabel = '';
    declineInterestButtonLabel = '';

    setCheckedRowsOnRefresh() {
        if (sessionStorage.getItem('checkedrowsWanted') && !this.isDetails) {
            this.checkedServiceAppointments = JSON.parse(sessionStorage.getItem('checkedrowsWanted'));
            sessionStorage.removeItem('checkedrowsWanted');
        }
        this.sendCheckedRows();
    }

    disconnectedCallback() {}

    renderedCallback() {
        this.setCheckedRowsOnRefresh();
        sessionStorage.setItem('checkedrowsSavedForRefreshWanted', JSON.stringify(this.checkedServiceAppointments));
    }

    filters = [];
    numberTimesCalled = 0;
    connectedCallback() {
        this.updateURL();
        this.setColumns();
        if (sessionStorage.getItem('checkedrowsSavedForRefreshWanted')) {
            this.checkedServiceAppointments = JSON.parse(sessionStorage.getItem('checkedrowsSavedForRefreshWanted'));
            sessionStorage.removeItem('checkedrowsSavedForRefreshWanted');
        }
        refreshApex(this.wiredAllServiceAppointmentsResult);
    }

    serviceResource;
    serviceResourceId;
    @wire(getServiceResource)
    wiredServiceresource(result) {
        if (result.data) {
            this.serviceResource = result.data;
            this.serviceResourceId = this.serviceResource.Id;
            this.filters = setDefaultFilters(this.serviceResource.HOT_PreferredRegions__c);
            if (this.wiredAllServiceAppointmentsResult !== null) {
                this.refresh();
            }
        }
    }

    noServiceAppointments = false;
    initialServiceAppointments = [];
    records = [];
    allServiceAppointmentsWired = [];
    wiredAllServiceAppointmentsResult;
    @wire(getWantedServiceAppointments)
    wiredAllServiceAppointmentsWired(result) {
        this.wiredAllServiceAppointmentsResult = result;
        if (result.data) {
            this.error = undefined;
            this.allServiceAppointmentsWired = result.data.map((x) => ({
                ...x,
                weekday: getDayOfWeek(x.EarliestStartTime),
                startAndEndDateWeekday: formatDatetimeinterval(x.EarliestStartTime, x.DueDate),
                isOtherProvider: x.HOT_Request__r?.IsOtherEconomicProvicer__c ? 'Ja' : 'Nei'
            }));
            this.noServiceAppointments = this.allServiceAppointmentsWired.length === 0;
            let tempRecords = [];
            for (let record of this.allServiceAppointmentsWired) {
                tempRecords.push(formatRecord(Object.assign({}, record), this.datetimeFields));
            }
            this.records = tempRecords;
            this.initialServiceAppointments = [...this.records];
            if (this.serviceResource !== null) {
                this.refresh();
                this.dataLoader = false;
            }
        } else if (result.error) {
            this.dataLoader = false;
            this.error = result.error;
            this.allServiceAppointmentsWired = undefined;
        }
    }

    refresh() {
        this.sendRecords();
        this.sendCheckedRows();
    }

    datetimeFields = [
        { name: 'StartAndEndDate', type: 'datetimeinterval', start: 'EarliestStartTime', end: 'DueDate' },
        { name: 'HOT_DeadlineDate__c', type: 'date' },
        { name: 'HOT_ReleaseDate__c', type: 'date', newName: 'ReleaseDate' }
    ];
    showServiceAppointmentDetailsModal = false;

    serviceAppointment;
    isDetails = false;
    showTable = true;
    goToRecordDetails(result) {
        this.serviceAppointment = undefined;
        let recordId = result.detail.Id;
        this.recordId = recordId;
        this.isDetails = !!this.recordId;
        for (let serviceAppointment of this.records) {
            if (recordId === serviceAppointment.Id) {
                this.serviceAppointment = serviceAppointment;
                this.serviceAppointment.weekday = getDayOfWeek(this.serviceAppointment.EarliestStartTime);
            }
        }
        this.showServiceAppointmentDetails();
    }

    hasFocused = false;
    showModalHeader = false;
    showSubmittedLoading = false;
    showSubmittedError = false;
    showSubmittedTrue = false;

    showServiceAppointmentDetails() {
        this.showServiceAppointmentDetailsModal = true;
        this.showModalHeader = true;
        const dialog = this.template.querySelector('dialog');
        dialog.showModal();
        dialog.focus();
    }

    @api recordId;
    updateURL() {
        let baseURL =
            window.location.protocol + '//' + window.location.host + window.location.pathname + '?list=wanted';
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
        this.sendDetail();
        return { id: recordIdToReturn, tab: 'wanted' };
    }

    errorMessage = '';
    spin = false;
    checkedServiceAppointments = [];

    handleRowChecked(event) {
        this.checkedServiceAppointments = event.detail.checkedRows;
        this.sendCheckedRows();
    }

    hideSubmitIndicators() {
        this.showSubmittedError = false;
        this.showSubmittedLoading = false;
        this.showSubmittedTrue = false;
    }

    closeModal() {
        this.hideSubmitIndicators();
        this.sendInterestAll = false;
        this.showModalHeader = false;
        const dialog = this.template.querySelector('dialog');
        dialog.close();
    }
    acceptInterest() {
        this.isDetails = false;
        this.showModalHeader = false;
        this.checkedServiceAppointments = [];
        this.processMessage = 'Melder interesse for oppdraget';
        this.spin = true;
        this.showSubmittedLoading = true;
        updateInterestedResource({
            saId: this.serviceAppointment.Id,
            srId: this.serviceResourceId
        })
            .then(() => {
                this.spin = false;
                this.showSubmittedLoading = false;
                this.showSubmittedTrue = true;
                this.processMessageResult = 'Interesse er meldt.';
                let currentFilters = this.filters;
                refreshApex(this.wiredAllServiceAppointmentsResult).then(() => {});
            })
            .catch((error) => {
                this.spin = false;
                this.showSubmittedLoading = false;
                this.showSubmittedError = true;
                this.errorMessage = JSON.stringify(error);
                this.sendInterestAll = false;
            });
    }
    declineInterest() {
        this.isDetails = false;
        this.showModalHeader = false;
        this.checkedServiceAppointments = [];
        this.processMessage = 'Avslår interesse for oppdrag';
        this.spin = true;
        this.showSubmittedLoading = true;
        declineInterestedResource({
            saId: this.serviceAppointment.Id,
            srId: this.serviceResourceId
        })
            .then(() => {
                this.spin = false;
                this.showSubmittedLoading = false;
                this.showSubmittedTrue = true;
                this.processMessageResult = 'Avslått interesse for oppdraget';
                let currentFilters = this.filters;
                refreshApex(this.wiredAllServiceAppointmentsResult).then(() => {});
            })
            .catch((error) => {
                this.spin = false;
                this.showSubmittedLoading = false;
                this.showSubmittedError = true;
                this.errorMessage = JSON.stringify(error);
                this.sendInterestAll = false;
            });
    }

    getRecord(id) {
        for (let record of this.records) {
            if (record.Id === id) {
                return record;
            }
        }
        return null;
    }
    filteredRecordsLength = 0;
    registerInterestChecked() {
        this.showServiceAppointmentDetailsModal = true;
        this.isDetails = false;
        this.processMessage = 'Melder interesse...';
        this.showServiceAppointmentDetails();
        this.showModalHeader = false;
        this.spin = true;
        this.showSubmittedLoading = true;
        this.checkedServiceAppointments = this.template.querySelector('c-hot_freelance-common-table').getCheckedRows();

        if (this.checkedServiceAppointments.length === 0) {
            this.closeModal();
            return;
        }
        updateInterestedResourceChecked({
            saIdsList: this.checkedServiceAppointments,
            srId: this.serviceResourceId
        })
            .then(() => {
                this.processMessageResult = 'Interesse er meldt.';
                this.spin = false;
                this.showSubmittedLoading = false;
                this.showSubmittedTrue = true;
                this.checkedServiceAppointments = this.template
                    .querySelector('c-hot_freelance-common-table')
                    .unsetCheckboxes();

                this.checkedServiceAppointments = [];
                refreshApex(this.wiredAllServiceAppointmentsResult).then(() => {});
            })
            .catch((error) => {
                this.spin = false;
                this.showSendInterest = true;
                this.showSubmittedLoading = false;
                this.showSubmittedError = true;
                this.errorMessage = JSON.stringify(error);
                this.processMessage = this.errorMessage;
            });
    }
    declineInterestChecked() {
        this.showServiceAppointmentDetailsModal = true;
        this.isDetails = false;
        this.showServiceAppointmentDetails();
        this.showModalHeader = false;
        this.checkedServiceAppointments = this.template.querySelector('c-hot_freelance-common-table').getCheckedRows();

        if (this.checkedServiceAppointments.length === 0) {
            this.closeModal();
            return;
        }
        this.processMessage = 'Avslår interesse...';
        this.spin = true;
        this.showSubmittedLoading = true;
        declineInterestedResourceChecked({
            saIdsList: this.checkedServiceAppointments,
            srId: this.serviceResourceId
        })
            .then(() => {
                this.processMessageResult = 'Avslått interesse.';
                this.spin = false;
                this.showSubmittedLoading = false;
                this.showSubmittedTrue = true;
                this.checkedServiceAppointments = this.template
                    .querySelector('c-hot_freelance-common-table')
                    .unsetCheckboxes();

                this.checkedServiceAppointments = [];
                refreshApex(this.wiredAllServiceAppointmentsResult).then(() => {});
            })
            .catch((error) => {
                this.spin = false;
                this.showSendInterest = true;
                this.showSubmittedLoading = false;
                this.showError = true;
                this.errorMessage = JSON.stringify(error);
                this.processMessage = this.errorMessage;
            });
    }
}
