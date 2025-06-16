import { LightningElement, wire, track, api } from 'lwc';
import getOpenServiceAppointments from '@salesforce/apex/HOT_OpenServiceAppointmentListController.getOpenServiceAppointments';
import createInterestedResources from '@salesforce/apex/HOT_OpenServiceAppointmentListController.createInterestedResources';
import getServiceResource from '@salesforce/apex/HOT_Utility.getServiceResource';
import { columns, inDetailsColumns, mobileColumns } from './columns';
import { refreshApex } from '@salesforce/apex';
import { defaultFilters, compare, setDefaultFilters } from './filters';
import { formatRecord, formatDatetimeinterval } from 'c/datetimeFormatterNorwegianTime';
import Hot_openServiceAppointmentsModal from 'c/hot_openServiceAppointmentsModal';

export default class Hot_openServiceAppointments extends LightningElement {
    @track columns = [];
    @track inDetailsColumns = [];
    @track isMobile;
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
        if (sessionStorage.getItem('openfilters')) {
            this.applyFilter({
                detail: { filterArray: JSON.parse(sessionStorage.getItem('openfilters')), setRecords: true }
            });
            sessionStorage.removeItem('openfilters');
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
    @track allServiceAppointmentsWiredMobile = [];
    wiredAllServiceAppointmentsResult;
    @wire(getOpenServiceAppointments)
    wiredAllServiceAppointmentsWired(result) {
        this.wiredAllServiceAppointmentsResult = result;
        if (result.data) {
            this.error = undefined;
            this.allServiceAppointmentsWired = result.data.map((x) => ({
                ...x,
                isUrgent: x.HOT_IsUrgent__c,
                startAndEndDateWeekday:
                    formatDatetimeinterval(x.EarliestStartTime, x.DueDate) +
                    ' ' +
                    this.getDayOfWeek(x.EarliestStartTime),
                weekday: this.getDayOfWeek(x.EarliestStartTime)
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

    getModalSize() {
        return window.screen.width < 768 ? 'full' : 'small';
    }

    async goToRecordDetails(result) {
        const { success, error } = await Hot_openServiceAppointmentsModal.open({
            size: 'small',
            result: result,
            records: this.records
        });
        if (success) {
            refreshApex(this.wiredAllServiceAppointmentsResult);
        }
    }
    @api recordId;
    updateURL() {
        let baseURL = window.location.protocol + '//' + window.location.host + window.location.pathname + '?list=open';
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
        return { id: recordIdToReturn, tab: 'open' };
    }

    @track checkedServiceAppointments = [];

    handleRowChecked(event) {
        this.checkedServiceAppointments = event.detail.checkedRows;
        this.sendCheckedRows();
    }

    showSendInterest = false;
    @track serviceAppointmentCommentDetails = [];
    sendInterest(result) {
        this.checkedServiceAppointments = [];
        this.serviceAppointmentCommentDetails = [];
        try {
            if (this.isMobile) {
                this.template
                    .querySelector('c-hot_freelance-table-list-mobile')
                    .getCheckedRows()
                    .forEach((row) => {
                        this.checkedServiceAppointments.push(row);
                        this.serviceAppointmentCommentDetails.push(this.getRecord(row));
                    });
            } else {
                this.template
                    .querySelector('c-table')
                    .getCheckedRows()
                    .forEach((row) => {
                        this.checkedServiceAppointments.push(row);
                        this.serviceAppointmentCommentDetails.push(this.getRecord(row));
                    });
            }
        } catch (error) {
            console.error(error);
        }
        if (this.checkedServiceAppointments.length === 0) {
            this.showSendInterest = false;
            return;
        }
        this.showSendInterest = false;
        this.showCommentPage(result);
    }

    sendInterestAllComplete = false;
    sendInterestAll = false;
    sendInterestSeries(result) {
        this.serviceAppointmentCommentDetails = [];
        this.sendInterestAll = true;
        this.serviceAppointmentCommentDetails.push(...this.seriesRecords);
        this.showCommentPage(result);
    }

    async showCommentPage(result) {
        const { success, error } = await Hot_openServiceAppointmentsModal.open({
            size: 'small',
            records: this.records,
            result: result,
            serviceAppointmentCommentDetails: this.serviceAppointmentCommentDetails,
            checkedServiceAppointments: this.checkedServiceAppointments,
            sendInterestAll: this.sendInterestAll
        });
        if (success) {
            this.showSendInterest = false;
            this.checkedServiceAppointments = [];
            refreshApex(this.wiredAllServiceAppointmentsResult);
        }
    }

    closeModal() {
        if (this.sendInterestAllComplete) {
            refreshApex(this.wiredAllServiceAppointmentsResult);
            this.goBack();
        }
        this.sendInterestAllComplete = false;
        this.sendInterestAll = false;
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
        let sameValues = true;
        let sessionUndefined = false;
        if (filterFromSessionStorage === null || filterFromSessionStorage === undefined) {
            sessionUndefined = true;
        } else if (this.filters.length !== filterFromSessionStorage.length && sessionUndefined == false) {
            sameValues = false;
        } else {
            for (let i = 0; i < this.filters.length; i++) {
                if (JSON.stringify(this.filters[i]) !== JSON.stringify(filterFromSessionStorage[i])) {
                    sameValues = false;
                    break;
                }
            }
        }
        sessionStorage.setItem('openSessionFilter', JSON.stringify(this.filters));
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
