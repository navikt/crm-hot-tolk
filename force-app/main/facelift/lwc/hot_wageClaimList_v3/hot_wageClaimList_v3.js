import { LightningElement, wire, api } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getMyWageClaims from '@salesforce/apex/HOT_WageClaimListController.getMyWageClaimsOfNewType';
import getThreadId from '@salesforce/apex/HOT_WageClaimListController.getThreadId';
import createThread from '@salesforce/apex/HOT_MessageHelper.createThread';
import { getParametersFromURL } from 'c/hot_URIDecoder';
import getWageClaimDetails from '@salesforce/apex/HOT_WageClaimListController.getWageClaimDetails';
import { columns, mobileColumns } from './columns';
import { NavigationMixin } from 'lightning/navigation';
import { formatRecord } from 'c/datetimeFormatterNorwegianTime';
import { defaultFilters, compare } from './filters';
import icons from '@salesforce/resourceUrl/ikoner';
import icons2 from '@salesforce/resourceUrl/icons';

export default class Hot_wageClaimList_v3 extends NavigationMixin(LightningElement) {
    exitCrossIcon = icons + '/Close/Close.svg';
    warningicon = icons2 + '/warningicon.svg';
    columns = [];
    filters = [];
    setColumns() {
        if (window.screen.width > 576) {
            this.columns = columns;
        } else {
            this.columns = mobileColumns;
        }
    }

    get hasResult() {
        return !this.dataLoader && this.wageClaims && this.wageClaims.length > 0;
    }

    get noWageClaimsResult() {
        return !this.dataLoader && this.allWageClaimsWired.length === 0;
    }

    get noFilteredRecordsResult() {
        return (
            !this.dataLoader &&
            this.allWageClaimsWired.length > 0 &&
            this.wageClaims.length === 0 &&
            this.filters?.length > 0
        );
    }

    isDisabledGoToThread = false;

    dataLoader = true;
    noWageClaims = false;
    wageClaims = [];
    allWageClaimsWired = [];
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
            this.dataLoader = false;
        } else if (result.error) {
            this.dataLoader = false;
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

    datetimeFields = [{ name: 'StartAndEndDate', type: 'datetimeinterval', start: 'StartTime__c', end: 'EndTime__c' }];

    recordId;
    showDetails = false;
    urlRedirect = false;

    connectedCallback() {
        this.setColumns();
        this.getParams();
        this.updateURL();
        refreshApex(this.wiredWageClaimsResult);
    }
    hasAccess = true;
    wageClaim;
    isWageClaimDetails = false;
    goToRecordDetails(result) {
        this.hasAccess = true;
        this.isDisabledGoToThread = false;
        this.showServiceAppointmentDetails();
        this.wageClaim = undefined;
        let recordId = result.detail.Id;
        this.recordId = recordId;
        this.isWageClaimDetails = !!this.recordId;
        for (let wageClaim of this.wageClaims) {
            if (recordId === wageClaim.Id) {
                this.wageClaim = wageClaim;
                this.wageClaim.weekday = getDayOfWeek(this.wageClaim.StartTime__c);
            }
        }
        this.updateURL();
    }

    goToRecordDetailsFromNotification(wageClaimId) {
        this.hasAccess = false;
        getWageClaimDetails({ recordId: wageClaimId })
            .then((result) => {
                this.isDisabledGoToThread = false;
                this.hasAccess = true;
                this.showServiceAppointmentDetails();
                this.wageClaim = result;
                this.wageClaim = formatRecord(Object.assign({}, result), this.datetimeFields);
                this.wageClaim.weekday = this.getDayOfWeek(this.wageClaim.StartTime__c);
                this.recordId = wageClaimId;
                this.isWageClaimDetails = !!this.recordId;
            })
            .catch((error) => {
                console.log(error);
                this.showServiceAppointmentDetails();
            });
        this.updateURL();
    }

    @api recordId;
    updateURL() {
        let baseURL =
            window.location.protocol +
            '//' +
            window.location.host +
            window.location.pathname +
            '?list=wageClaimsOfNewType';
        if (this.recordId) {
            baseURL += '&id=' + this.recordId;
        }
        window.history.pushState({ path: baseURL }, '', baseURL);
    }
    treadId;
    goToWageClaimThread() {
        this.isDisabledGoToThread = true;
        getThreadId({ wageClaimeId: this.recordId }).then((result) => {
            if (result != '') {
                this.threadId = result;
                this.navigateToThread(this.threadId);
            } else {
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

    noCancelButton = false;
    modalHeader = 'Noe gikk galt';
    modalContent = 'Prøv igjen';
    confirmButtonLabel = 'Ok';

    cancelRetraction() {
        this.isRetracting = false;
    }
    showModal() {
        this.template.querySelector('c-alertdialog').showModal();
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
    noFilteredRecords = false;
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
        this.noFilteredRecords = this.filteredRecordsLength === 0 && this.filters.length > 0;

        if (setRecords) {
            this.wageClaims = filteredRecords;
        }
        return this.filteredRecordsLength;
    }
    handleRefreshRecords() {
        refreshApex(this.wiredWageClaimsResult);
    }
    showServiceAppointmentDetailsModal = false;

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
    showModal() {
        this.template.querySelector('c-alertdialog').showModal();
    }
    get appointmentNumber() {
        return this.wageClaim?.ServiceAppointmentName__c || '';
    }

    get appointmentTime() {
        return this.wageClaim?.StartAndEndDate || '';
    }

    get appointmentCity() {
        return this.wageClaim?.ServiceAppointmentCity__c || '';
    }

    get workType() {
        return this.wageClaim?.WorkTypeName__c || '';
    }

    get assignmentType() {
        return this.wageClaim?.AssignmentType__c || '';
    }

    get ownerName() {
        return this.wageClaim?.ServiceAppointment__r?.HOT_Request__r?.OwnerName__c || '';
    }

    get degreeOfHearingAndVisualImpairment() {
        return this.wageClaim?.DegreeOfHearingAndVisualImpairment__c || '';
    }
}
