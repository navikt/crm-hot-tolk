import { LightningElement, wire, track, api } from 'lwc';
import getWantedServiceAppointments from '@salesforce/apex/HOT_wantedSRListController.getWantedServiceAppointments';
import updateInterestedResource from '@salesforce/apex/HOT_wantedSRListController.updateInterestedResource';
import updateInterestedResourceChecked from '@salesforce/apex/HOT_wantedSRListController.updateInterestedResourceChecked';
import declineInterestedResourceChecked from '@salesforce/apex/HOT_wantedSRListController.declineInterestedResourceChecked';
import declineInterestedResource from '@salesforce/apex/HOT_wantedSRListController.declineInterestedResource';
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

    acceptInterest() {
        this.isDetails = false;
        this.checkedServiceAppointments = [];
        this.processMessage = 'Melder interesse for oppdraget';
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
                this.processMessageResult = 'Interesse er meldt.';
                let currentFilters = this.filters;
                refreshApex(this.wiredAllServiceAppointmentsResult).then(() => {});
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
        this.isDetails = false;
        this.checkedServiceAppointments = [];
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
                refreshApex(this.wiredAllServiceAppointmentsResult).then(() => {});
            })
            .catch((error) => {
                this.spin = false;
                this.template.querySelector('.submitted-loading').classList.add('hidden');
                this.template.querySelector('.submitted-error').classList.remove('hidden');
                this.errorMessage = JSON.stringify(error);
                this.sendInterestAll = false;
            });
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

    @track filters = [];
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
    formatDatetime(Start, DueDate) {
        const datetimeStart = new Date(Start);
        const dayStart = datetimeStart.getDate().toString().padStart(2, '0');
        const monthStart = (datetimeStart.getMonth() + 1).toString().padStart(2, '0');
        const yearStart = datetimeStart.getFullYear();
        const hoursStart = datetimeStart.getHours().toString().padStart(2, '0');
        const minutesStart = datetimeStart.getMinutes().toString().padStart(2, '0');

        const datetimeEnd = new Date(DueDate);
        const hoursEnd = datetimeEnd.getHours().toString().padStart(2, '0');
        const minutesEnd = datetimeEnd.getMinutes().toString().padStart(2, '0');

        const formattedDatetime = `${dayStart}.${monthStart}.${yearStart} ${hoursStart}:${minutesStart} - ${hoursEnd}:${minutesEnd}`;
        return formattedDatetime;
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
    wiredAllServiceAppointmentsResult;
    @wire(getWantedServiceAppointments)
    wiredAllServiceAppointmentsWired(result) {
        this.wiredAllServiceAppointmentsResult = result;
        if (result.data) {
            this.error = undefined;
            this.allServiceAppointmentsWired = result.data.map((x) => ({
                ...x,
                weekday: this.getDayOfWeek(x.EarliestStartTime),
                isUrgent: x.HOT_IsUrgent__c,
                startAndEndDateWeekday:
                    this.formatDatetime(x.EarliestStartTime, x.DueDate) + ' ' + this.getDayOfWeek(x.EarliestStartTime)
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
        this.sendRecords();
        this.sendCheckedRows();
    }

    datetimeFields = [
        { name: 'StartAndEndDate', type: 'datetimeinterval', start: 'EarliestStartTime', end: 'DueDate' },
        { name: 'HOT_DeadlineDate__c', type: 'date' },
        { name: 'HOT_ReleaseDate__c', type: 'date', newName: 'ReleaseDate' }
    ];

    @track serviceAppointment;
    isDetails = false;
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
                this.serviceAppointment.weekday = this.getDayOfWeek(this.serviceAppointment.EarliestStartTime);
            }
        }
        this.showServiceAppointmentDetails();
    }
    showServiceAppointmentDetails() {
        this.template.querySelector('.record-details-container').classList.remove('hidden');
        this.template.querySelector('.submitted-error').classList.add('hidden');
        this.template.querySelector('.submitted-loading').classList.add('hidden');
        this.template.querySelector('.submitted-true').classList.add('hidden');
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

    hideSubmitIndicators() {
        this.template.querySelector('.submitted-error').classList.add('hidden');
        this.template.querySelector('.submitted-loading').classList.add('hidden');
        this.template.querySelector('.submitted-true').classList.add('hidden');
    }

    closeModal() {
        this.sendInterestAll = false;
        this.template.querySelector('.commentPage').classList.add('hidden');
        this.template.querySelector('.serviceAppointmentDetails').classList.add('hidden');
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
        this.template.querySelector('.submitted-true').classList.add('hidden');
        this.isDetails = false;
        this.processMessage = 'Melder interesse...';
        this.spin = true;
        this.template.querySelector('.comments-dialog-container').classList.remove('hidden');
        this.template.querySelector('.serviceAppointmentDetails').classList.remove('hidden');
        this.template.querySelector('.submitted-loading').classList.remove('hidden');
        if (this.isMobile) {
            this.checkedServiceAppointments = this.template
                .querySelector('c-hot_freelance-table-list-mobile')
                .getCheckedRows();
        } else {
            this.checkedServiceAppointments = this.template.querySelector('c-table').getCheckedRows();
        }

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
                this.template.querySelector('.submitted-loading').classList.add('hidden');
                this.template.querySelector('.submitted-true').classList.remove('hidden');
                if (this.isMobile) {
                    this.checkedServiceAppointments = this.template
                        .querySelector('c-hot_freelance-table-list-mobile')
                        .unsetCheckboxes();
                } else {
                    this.checkedServiceAppointments = this.template.querySelector('c-table').unsetCheckboxes();
                }
                this.checkedServiceAppointments = [];
                refreshApex(this.wiredAllServiceAppointmentsResult).then(() => {});
            })
            .catch((error) => {
                this.spin = false;
                this.showSendInterest = true;
                this.template.querySelector('.submitted-loading').classList.add('hidden');
                this.template.querySelector('.submitted-error').classList.remove('hidden');
                this.errorMessage = JSON.stringify(error);
                this.processMessage = this.errorMessage;
            });
    }
    declineInterestChecked() {
        this.template.querySelector('.submitted-true').classList.add('hidden');
        this.isDetails = false;
        if (this.isMobile) {
            this.checkedServiceAppointments = this.template
                .querySelector('c-hot_freelance-table-list-mobile')
                .getCheckedRows();
        } else {
            this.checkedServiceAppointments = this.template.querySelector('c-table').getCheckedRows();
        }

        if (this.checkedServiceAppointments.length === 0) {
            this.closeModal();
            return;
        }
        this.processMessage = 'Avslår interesse...';
        this.spin = true;
        this.template.querySelector('.comments-dialog-container').classList.remove('hidden');
        this.template.querySelector('.serviceAppointmentDetails').classList.remove('hidden');
        this.template.querySelector('.submitted-loading').classList.remove('hidden');
        this.checkedServiceAppointments.forEach((element) => {
            console.log(element);
        });
        declineInterestedResourceChecked({
            saIdsList: this.checkedServiceAppointments,
            srId: this.serviceResourceId
        })
            .then(() => {
                this.processMessageResult = 'Avslått interesse.';
                this.spin = false;
                this.template.querySelector('.submitted-loading').classList.add('hidden');
                this.template.querySelector('.submitted-true').classList.remove('hidden');
                if (this.isMobile) {
                    this.checkedServiceAppointments = this.template
                        .querySelector('c-hot_freelance-table-list-mobile')
                        .unsetCheckboxes();
                } else {
                    this.checkedServiceAppointments = this.template.querySelector('c-table').unsetCheckboxes();
                }
                this.checkedServiceAppointments = [];
                refreshApex(this.wiredAllServiceAppointmentsResult).then(() => {});
            })
            .catch((error) => {
                this.spin = false;
                this.showSendInterest = true;
                this.template.querySelector('.submitted-loading').classList.add('hidden');
                this.template.querySelector('.submitted-error').classList.remove('hidden');
                this.errorMessage = JSON.stringify(error);
                this.processMessage = this.errorMessage;
            });
    }
}
