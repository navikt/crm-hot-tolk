import { LightningElement, wire, track, api } from 'lwc';
import getWantedServiceAppointments from '@salesforce/apex/HOT_wantedSRListController.getWantedServiceAppointments';
import updateInterestedResource from '@salesforce/apex/HOT_wantedSRListController.updateInterestedResource';
import declineInterestedResource from '@salesforce/apex/HOT_wantedSRListController.declineInterestedResource';
import createInterestedResources from '@salesforce/apex/HOT_OpenServiceAppointmentListController.createInterestedResources';
import getServiceResource from '@salesforce/apex/HOT_Utility.getServiceResource';
import { columns, inDetailsColumns, mobileColumns } from './columns';
import { refreshApex } from '@salesforce/apex';
import { defaultFilters, compare, setDefaultFilters } from './filters';
import { formatRecord } from 'c/datetimeFormatter';

export default class Hot_wantedServiceAppointmentsList extends LightningElement {
    @track columns = [];
    @track inDetailsColumns = [];
    @track processMessage;
    @track processMessageResult;
    setColumns() {
        if (window.screen.width > 576) {
            this.columns = columns;
            this.inDetailsColumns = inDetailsColumns;
        } else {
            this.columns = mobileColumns;
            this.inDetailsColumns = inDetailsColumns;
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

    acceptInterest() {
        this.processMessage = 'Tildeler deg oppdraget';
        this.spin = true;
        this.template.querySelector('.record-details-container').classList.add('hidden');
        this.template.querySelector('.submitted-loading').classList.remove('hidden');
        updateInterestedResource({
            saId: this.serviceAppointment.Id,
            srId: this.serviceResourceId
        })
            .then(() => {
                this.spin = false;
                this.template.querySelector('.submitted-loading').classList.add('hidden');
                this.template.querySelector('.submitted-true').classList.remove('hidden');
                this.processMessageResult = 'Du ble tildelt oppdraget.';
                let currentFilters = this.filters;
                refreshApex(this.wiredAllServiceAppointmentsResult).then(() => {
                    this.applyFilter({ detail: { filterArray: currentFilters, setRecords: true } });
                });
            })
            .catch((error) => {
                this.spin = false;
                this.template.querySelector('.submitted-loading').classList.add('hidden');
                this.template.querySelector('.submitted-error').classList.remove('hidden');
                this.errorMessage = JSON.stringify(error);
                this.sendInterestAll = false;
            });
    }
    declineInterest() {
        this.processMessage = 'Avslår interesse for oppdrag';
        this.spin = true;
        this.template.querySelector('.record-details-container').classList.add('hidden');
        this.template.querySelector('.submitted-loading').classList.remove('hidden');
        declineInterestedResource({
            saId: this.serviceAppointment.Id,
            srId: this.serviceResourceId
        })
            .then(() => {
                this.spin = false;
                this.template.querySelector('.submitted-loading').classList.add('hidden');
                this.template.querySelector('.submitted-true').classList.remove('hidden');
                this.processMessageResult = 'Avslått interesse for oppdraget';
                let currentFilters = this.filters;
                refreshApex(this.wiredAllServiceAppointmentsResult).then(() => {
                    this.applyFilter({ detail: { filterArray: currentFilters, setRecords: true } });
                });
            })
            .catch((error) => {
                this.spin = false;
                this.template.querySelector('.submitted-loading').classList.add('hidden');
                this.template.querySelector('.submitted-error').classList.remove('hidden');
                this.errorMessage = JSON.stringify(error);
                this.sendInterestAll = false;
            });
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
    sendCheckedRows() {
        this.showSendInterest = this.checkedServiceAppointments.length > 0;
        this.sendInterestButtonLabel = 'Meld interesse til ' + this.checkedServiceAppointments.length + ' oppdrag';
        const eventToSend = new CustomEvent('sendcheckedrows', { detail: this.checkedServiceAppointments });
        this.dispatchEvent(eventToSend);
    }
    sendInterestButtonLabel = '';

    setPreviousFiltersOnRefresh() {
        if (sessionStorage.getItem('openfilters2')) {
            this.applyFilter({
                detail: { filterArray: JSON.parse(sessionStorage.getItem('openfilters2')), setRecords: true }
            });
            sessionStorage.removeItem('openfilters2');
        }

        this.sendFilters();
    }
    setCheckedRowsOnRefresh() {
        if (sessionStorage.getItem('checkedrows') && !this.isDetails) {
            this.checkedServiceAppointments = JSON.parse(sessionStorage.getItem('checkedrows'));
            sessionStorage.removeItem('checkedrows');
        }
        this.sendCheckedRows();
    }

    disconnectedCallback() {
        // Going back with browser back or back button on mouse forces page refresh and a disconnect
        // Save filters on disconnect to exist only within the current browser tab
        sessionStorage.setItem('checkedrows', JSON.stringify(this.checkedServiceAppointments));
    }

    renderedCallback() {
        this.setPreviousFiltersOnRefresh();
        this.setCheckedRowsOnRefresh();
        sessionStorage.setItem('checkedrowsSavedForRefresh', JSON.stringify(this.checkedServiceAppointments));
    }

    @track filters = [];
    numberTimesCalled = 0;
    connectedCallback() {
        this.updateURL();
        if (sessionStorage.getItem('checkedrowsSavedForRefresh')) {
            this.checkedServiceAppointments = JSON.parse(sessionStorage.getItem('checkedrowsSavedForRefresh'));
            sessionStorage.removeItem('checkedrowsSavedForRefresh');
        }
        this.setColumns();
        refreshApex(this.wiredAllServiceAppointmentsResult);
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
    @track serviceResource;
    @track serviceResourceId;
    @wire(getServiceResource)
    wiredServiceresource(result) {
        if (result.data) {
            this.serviceResource = result.data;
            this.serviceResourceId = this.serviceResource.Id;
            console.log('fant sr: ' + this.serviceResourceId);
            this.filters = setDefaultFilters(this.serviceResource.HOT_PreferredRegions__c);
            if (this.wiredAllServiceAppointmentsResult !== null) {
                this.refresh();
            }
        }
    }
    noServiceAppointments = false;
    initialServiceAppointments = [];
    @track records = [];
    @track allServiceAppointmentsWired = [];
    wiredAllServiceAppointmentsResult;
    @wire(getWantedServiceAppointments)
    wiredAllServiceAppointmentsWired(result) {
        this.wiredAllServiceAppointmentsResult = result;
        if (result.data) {
            console.log('result: ' + result.data);
            this.error = undefined;
            this.allServiceAppointmentsWired = result.data.map((x) => ({
                ...x,
                weekday: this.getDayOfWeek(x.EarliestStartTime),
                isUrgent: x.HOT_IsUrgent__c
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
            }
        } else if (result.error) {
            this.error = result.error;
            this.allServiceAppointmentsWired = undefined;
        }
    }

    refresh() {
        let filterFromSessionStorage = JSON.parse(sessionStorage.getItem('openSessionFilter'));
        this.filters = filterFromSessionStorage === null ? defaultFilters() : filterFromSessionStorage;

        this.sendRecords();
        this.sendFilters();
        this.sendCheckedRows();
        this.applyFilter({ detail: { filterArray: this.filters, setRecords: true } });
    }

    datetimeFields = [
        { name: 'StartAndEndDate', type: 'datetimeinterval', start: 'EarliestStartTime', end: 'DueDate' },
        { name: 'HOT_DeadlineDate__c', type: 'date' },
        { name: 'HOT_ReleaseDate__c', type: 'date', newName: 'ReleaseDate' }
    ];

    @track serviceAppointment;
    isDetails = false;
    isSeries = false;
    seriesRecords = [];
    showTable = true;
    goToRecordDetails(result) {
        this.serviceAppointment = undefined;
        this.seriesRecords = [];
        let recordId = result.detail.Id;
        this.recordId = recordId;
        this.isDetails = !!this.recordId;
        for (let serviceAppointment of this.records) {
            if (recordId === serviceAppointment.Id) {
                this.serviceAppointment = serviceAppointment;
                this.isSeries = this.serviceAppointment.HOT_IsSerieoppdrag__c;
                this.serviceAppointment.weekday = this.getDayOfWeek(this.serviceAppointment.EarliestStartTime);
            }
        }
        for (let serviceAppointment of this.records) {
            if (this.serviceAppointment?.HOT_Request__c === serviceAppointment?.HOT_Request__c) {
                this.seriesRecords.push(serviceAppointment);
            }
        }
        this.isSeries = this.seriesRecords.length <= 1 ? false : true;
        this.showServiceAppointmentDetails();
    }
    showServiceAppointmentDetails() {
        this.template.querySelector('.serviceAppointmentDetails').classList.remove('hidden');
        this.template.querySelector('.serviceAppointmentDetails').focus();
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
    @track checkedServiceAppointments = [];

    handleRowChecked(event) {
        this.checkedServiceAppointments = event.detail.checkedRows;
        this.sendCheckedRows();
    }

    showSendInterest = false;
    @track serviceAppointmentCommentDetails = [];
    sendInterest() {
        this.hideSubmitIndicators();
        this.showCommentSection();
        this.checkedServiceAppointments = [];
        this.serviceAppointmentCommentDetails = [];
        try {
            this.template
                .querySelector('c-table')
                .getCheckedRows()
                .forEach((row) => {
                    this.checkedServiceAppointments.push(row);
                    this.serviceAppointmentCommentDetails.push(this.getRecord(row));
                });
        } catch (error) {
            console.log(error);
        }
        if (this.checkedServiceAppointments.length === 0) {
            this.showSendInterest = false;
            return;
        }
        this.showSendInterest = false;
        this.showCommentPage();
    }

    sendInterestAllComplete = false;
    sendInterestAll = false;
    sendInterestSeries() {
        this.template.querySelector('.serviceAppointmentDetails').classList.add('hidden');
        this.hideSubmitIndicators();
        this.showCommentSection();
        this.serviceAppointmentCommentDetails = [];
        this.sendInterestAll = true;
        this.serviceAppointmentCommentDetails.push(...this.seriesRecords);
        this.showCommentPage();
    }

    showCommentPage() {
        this.template.querySelector('.commentPage').classList.remove('hidden');
        this.template.querySelector('.commentPage').focus();
    }

    hideSubmitIndicators() {
        this.template.querySelector('.submitted-error').classList.add('hidden');
        this.template.querySelector('.submitted-loading').classList.add('hidden');
        this.template.querySelector('.submitted-true').classList.add('hidden');
    }

    closeModal() {
        if (this.sendInterestAllComplete) {
            refreshApex(this.wiredAllServiceAppointmentsResult).then(() => {
                // Since refreshApex causes the wired methods to run again, the default filters will override current filters.
                // Apply previous filter
                this.applyFilter({ detail: { filterArray: currentFilters, setRecords: true } });
            });
            this.goBack();
        }
        this.sendInterestAllComplete = false;
        this.sendInterestAll = false;
        this.template.querySelector('.commentPage').classList.add('hidden');
        this.template.querySelector('.serviceAppointmentDetails').classList.add('hidden');
    }

    showCommentSection() {
        this.template.querySelector('.comment-details').classList.remove('hidden');
        this.template.querySelector('.send-inn-button').classList.remove('hidden');
    }

    getRecord(id) {
        for (let record of this.records) {
            if (record.Id === id) {
                return record;
            }
        }
        return null;
    }
    isRemoveReleasedTodayButtonHidden = true;
    isReleasedTodayButtonHidden = false;
    releasedTodayFilter() {
        this.checkedServiceAppointments = [];
        this.noReleasedToday = false;
        const d = new Date();
        let year = d.getFullYear();
        let day = d.getDate();
        let month = d.getMonth() + 1;
        month = month < 10 ? '0' + month : month;
        day = day < 10 ? '0' + day : day;
        const formattedDate = `${year}-${month}-${day}`;
        this.filters[5].value[0].value = formattedDate;

        this.sendFilters();
        this.applyFilter({ detail: { filterArray: this.filters, setRecords: true } });
        this.isReleasedTodayButtonHidden = true;
        this.isRemoveReleasedTodayButtonHidden = false;
    }
    removeReleasedTodayFilter() {
        this.checkedServiceAppointments = [];
        this.filters[5].value[0].value = '';
        this.sendFilters();
        this.applyFilter({ detail: { filterArray: this.filters, setRecords: true } });
        this.isReleasedTodayButtonHidden = false;
        this.isRemoveReleasedTodayButtonHidden = true;
    }
    filteredRecordsLength = 0;
    @api
    applyFilter(event) {
        this.numberTimesCalled = this.numberTimesCalled + 1;
        let setRecords = event.detail.setRecords;
        this.filters = event.detail.filterArray;
        let filterFromSessionStorage = JSON.parse(sessionStorage.getItem('openSessionFilter'));
        sessionStorage.setItem('openSessionFilter', JSON.stringify(this.filters));
        let sameValues = true;
        if (this.filters.length !== filterFromSessionStorage.length) {
            sameValues = false;
        } else {
            for (let i = 0; i < this.filters.length; i++) {
                if (JSON.stringify(this.filters[i]) !== JSON.stringify(filterFromSessionStorage[i])) {
                    sameValues = false;
                    break;
                }
            }
        }
        if (sameValues) {
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
            this.checkedServiceAppointmentsFromSession = JSON.parse(
                sessionStorage.getItem('checkedrowsSavedForRefresh')
            );
        } else {
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
            this.checkedServiceAppointmentsFromSession = JSON.parse(
                sessionStorage.getItem('checkedrowsSavedForRefresh')
            );
            if (
                this.filteredRecordsLength != this.checkedServiceAppointmentsFromSession.length &&
                this.numberTimesCalled > 2
            ) {
                this.checkedServiceAppointments = [];
            }
        }
        return this.filteredRecordsLength;
    }
}
