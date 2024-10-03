import { LightningElement, wire, track, api } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getMyWageClaims from '@salesforce/apex/HOT_WageClaimListController.getMyWageClaims';
import retractAvailability from '@salesforce/apex/HOT_WageClaimListController.retractAvailability';
import getThreadId from '@salesforce/apex/HOT_WageClaimListController.getThreadId';
import createThread from '@salesforce/apex/HOT_MessageHelper.createThread';
import { columns, mobileColumns } from './columns';
import { NavigationMixin } from 'lightning/navigation';
import { formatRecord } from 'c/datetimeFormatter';
import { defaultFilters, compare } from './filters';
import { getParametersFromURL } from 'c/hot_URIDecoder';
import getWageClaimDetails from '@salesforce/apex/HOT_WageClaimListController.getWageClaimDetails';

export default class Hot_wageClaimList extends NavigationMixin(LightningElement) {
    @track columns = [];
    @track filters = [];
    setColumns() {
        if (window.screen.width > 576) {
            this.columns = columns;
        } else {
            this.columns = mobileColumns;
        }
    }
    @track Status;
    isNotRetractable = false;
    isDisabledGoToThread = false;
    noWageClaims = false;
    @track wageClaims = [];
    @track allWageClaimsWired = [];
    wiredWageClaimsResult;
    @wire(getMyWageClaims)
    wiredWageClaims(result) {
        this.wiredWageClaimsResult = result;
        if (result.data) {
            this.allWageClaimsWired = result.data;
            this.noWageClaims = this.allWageClaimsWired.length === 0;
            this.error = undefined;
            let tempRecords = [];
            for (let record of result.data) {
                tempRecords.push(formatRecord(Object.assign({}, record), this.datetimeFields));
            }
            this.wageClaims = tempRecords;
            this.allWageClaimsWired = this.wageClaims;
            this.refresh();
        } else if (result.error) {
            this.error = result.error;
            this.allWageClaimsWired = undefined;
        }
    }

    getParams() {
        let parsed_params = getParametersFromURL() ?? '';
        if ((parsed_params.from == 'calendar' || parsed_params.from == 'mine-varsler') && parsed_params.id != '') {
            this.goToRecordDetailsFromNotification(parsed_params.id);
        }
    }

    refresh() {
        let filterFromSessionStorage = JSON.parse(sessionStorage.getItem('wageClaimSessionFilter'));
        this.filters = filterFromSessionStorage === null ? defaultFilters() : filterFromSessionStorage;
        this.sendRecords();
        this.sendFilters();
        this.applyFilter({ detail: { filterArray: this.filters, setRecords: true } });
    }

    setPreviousFiltersOnRefresh() {
        if (sessionStorage.getItem('wageclaimfilters')) {
            this.applyFilter({
                detail: { filterArray: JSON.parse(sessionStorage.getItem('wageclaimfilters')), setRecords: true }
            });
            sessionStorage.removeItem('wageclaimfilters');
        }
        this.sendFilters();
    }

    disconnectedCallback() {
        // Going back with browser back or back button on mouse forces page refresh and a disconnect
        // Save filters on disconnect to exist only within the current browser tab
        sessionStorage.setItem('wageclaimfilters', JSON.stringify(this.filters));
    }

    renderedCallback() {
        this.setPreviousFiltersOnRefresh();
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

    datetimeFields = [{ name: 'StartAndEndDate', type: 'datetimeinterval', start: 'StartTime__c', end: 'EndTime__c' }];

    connectedCallback() {
        this.setColumns();
        this.getParams();
        this.updateURL();
        refreshApex(this.wiredWageClaimsResult);
    }
    closeModal() {
        this.template.querySelector('.serviceAppointmentDetails').classList.add('hidden');
        this.recordId = undefined;
        this.updateURL();
    }
    @track wageClaim;
    isWageClaimDetails = false;
    goToRecordDetails(result) {
        this.isDisabledGoToThread = false;
        this.template.querySelector('.serviceAppointmentDetails').classList.remove('hidden');
        this.template.querySelector('.serviceAppointmentDetails').focus();
        this.wageClaim = undefined;
        this.Status = result.detail.Status__c;
        let recordId = result.detail.Id;
        this.recordId = recordId;
        if (result.detail.Status__c == 'Åpen') {
            this.isNotRetractable = false;
        } else {
            this.isNotRetractable = true;
        }
        this.isWageClaimDetails = !!this.recordId;
        for (let wageClaim of this.wageClaims) {
            if (recordId === wageClaim.Id) {
                this.wageClaim = wageClaim;
                this.wageClaim.weekday = this.getDayOfWeek(this.wageClaim.StartTime__c);
            }
        }
        this.updateURL();
    }

    goToRecordDetailsFromNotification(wageClaimId) {
        getWageClaimDetails({ recordId: wageClaimId })
            .then((result) => {
                this.isDisabledGoToThread = false;

                this.template.querySelector('.serviceAppointmentDetails').classList.remove('hidden');
                this.template.querySelector('.serviceAppointmentDetails').focus();

                this.isNotRetractable = result.Status__c != 'Open';
                this.wageClaim = result;
                this.wageClaim = formatRecord(Object.assign({}, result), this.datetimeFields);
                this.wageClaim.weekday = this.getDayOfWeek(this.wageClaim.StartTime__c);
                this.recordId = wageClaimId;
                this.Status = result.Status__c;
                this.isWageClaimDetails = !!this.recordId;
            })
            .catch((error) => console.log(error));
        this.updateURL();
    }

    treadId;
    goToWageClaimThread() {
        this.isDisabledGoToThread = true;
        getThreadId({ wageClaimeId: this.recordId }).then((result) => {
            if (result != '') {
                this.threadId = result;
                this.navigateToThread(this.threadId);
            } else {
                console.log('tråd finnes ikke');
                console.log('accountid: ' + this.wageClaim.ServiceResource__r.AccountId);
                createThread({ recordId: this.recordId, accountId: this.wageClaim.ServiceResource__r.AccountId })
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
    navigateToThread(recordId) {
        const baseUrl = '/samtale-frilans';
        const attributes = `recordId=${recordId}&from=mine-oppdrag&list=wageClaim`;
        const url = `${baseUrl}?${attributes}`;

        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: url
            }
        });
    }

    @api recordId;
    updateURL() {
        let baseURL =
            window.location.protocol + '//' + window.location.host + window.location.pathname + '?list=wageClaim';
        if (this.recordId) {
            baseURL += '&id=' + this.recordId;
        }
        window.history.pushState({ path: baseURL }, '', baseURL);
    }

    @api goBack() {
        let recordIdToReturn = this.recordId;
        this.recordId = undefined;
        this.isWageClaimDetails = false;
        this.sendDetail();
        return { id: recordIdToReturn, tab: 'wageClaim' };
    }
    noCancelButton = false;
    modalHeader = 'Varsel';
    modalContent =
        'Er du sikker på at du vil fjerne tilgjengeligheten din for dette tidspunktet? Du vil da ikke ha krav på lønn.';
    @track confirmButtonLabel = 'Ja';

    handleAlertDialogClick(event) {
        if (event.detail === 'confirm') {
            this.retractAvailability();
        }
    }
    showModal() {
        this.template.querySelector('c-alertdialog').showModal();
    }
    retractAvailability() {
        try {
            retractAvailability({ recordId: this.wageClaim.Id }).then(() => {
                this.isNotRetractable = true;
                this.Status = 'Tilbaketrukket tilgjengelighet';
                refreshApex(this.wiredWageClaimsResult);
            });
        } catch (error) {
            alert(JSON.stringify(error));
        }
    }
    sendFilters() {
        const eventToSend = new CustomEvent('sendfilters', { detail: this.filters });
        this.dispatchEvent(eventToSend);
    }
    sendRecords() {
        const eventToSend = new CustomEvent('sendrecords', { detail: this.allWageClaimsWired });
        this.dispatchEvent(eventToSend);
    }
    sendDetail() {
        const eventToSend = new CustomEvent('senddetail', { detail: this.isWageClaimDetails });
        this.dispatchEvent(eventToSend);
    }
    filteredRecordsLength = 0;
    @api
    applyFilter(event) {
        let setRecords = event.detail.setRecords;
        this.filters = event.detail.filterArray;
        sessionStorage.setItem('wageClaimSessionFilter', JSON.stringify(this.filters));
        let filteredRecords = [];
        let records = this.allWageClaimsWired;
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
            this.wageClaims = filteredRecords;
        }
        return this.filteredRecordsLength;
    }
}
