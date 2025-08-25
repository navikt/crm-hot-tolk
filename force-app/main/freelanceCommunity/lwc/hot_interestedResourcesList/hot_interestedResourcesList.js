import { LightningElement, wire, track, api } from 'lwc';
import getInterestedResources from '@salesforce/apex/HOT_InterestedResourcesListController.getInterestedResources';
import getMyThreads from '@salesforce/apex/HOT_ThreadListController.getMyThreadsIR';
import getInterestedResourceDetails from '@salesforce/apex/HOT_InterestedResourcesListController.getInterestedResourceDetails';
import checkAccessToSA from '@salesforce/apex/HOT_InterestedResourcesListController.checkAccessToSA';
import retractInterest from '@salesforce/apex/HOT_InterestedResourcesListController.retractInterest';
import getThreadDispatcherId from '@salesforce/apex/HOT_InterestedResourcesListController.getThreadDispatcherId';
import getThreadDispatcherIdSA from '@salesforce/apex/HOT_InterestedResourcesListController.getThreadDispatcherIdSA';
import createThreadInterpreter from '@salesforce/apex/HOT_MessageHelper.createThreadInterpreter';
import { formatRecord, formatDatetimeinterval } from 'c/datetimeFormatterNorwegianTime';
import getContactId from '@salesforce/apex/HOT_MessageHelper.getUserContactId';
import getServiceResource from '@salesforce/apex/HOT_Utility.getServiceResource';
import { refreshApex } from '@salesforce/apex';
import { getParametersFromURL } from 'c/hot_URIDecoder';
import { columns, mobileColumns, iconByValue } from './columns';
import { defaultFilters, compare } from './filters';
import { getDayOfWeek } from 'c/hot_commonUtils';
import { NavigationMixin } from 'lightning/navigation';
import icons from '@salesforce/resourceUrl/ikoner';

export default class Hot_interestedResourcesList extends NavigationMixin(LightningElement) {
    exitCrossIcon = icons + '/Close/Close.svg';
    @track columns = [];
    @track filters = [];
    @track iconByValue = iconByValue;
    @track isGoToThreadButtonDisabled = false;
    @track hasAccess = true;

    setColumns() {
        if (window.screen.width > 576) {
            this.columns = columns;
        } else {
            this.columns = mobileColumns;
        }
    }

    get hasResult() {
        return !this.dataLoader && this.records && this.records.length > 0;
    }

    get noInterestedResourcesResult() {
        return !this.dataLoader && this.initialInterestedResources.length === 0;
    }

    get noFilteredRecordsResult() {
        return (
            !this.dataLoader &&
            this.initialInterestedResources.length > 0 &&
            this.records.length === 0 &&
            this.filters?.length > 0
        );
    }

    sendFilters() {
        const eventToSend = new CustomEvent('sendfilters', { detail: this.filters });
        this.dispatchEvent(eventToSend);
    }
    sendRecords() {
        const eventToSend = new CustomEvent('sendrecords', { detail: this.initialInterestedResources });
        this.dispatchEvent(eventToSend);
    }
    sendDetail() {
        const eventToSend = new CustomEvent('senddetail', { detail: this.isDetails });
        this.dispatchEvent(eventToSend);
    }

    setPreviousFiltersOnRefresh() {
        if (sessionStorage.getItem('interestedfilters')) {
            this.applyFilter({
                detail: { filterArray: JSON.parse(sessionStorage.getItem('interestedfilters')), setRecords: true }
            });
            sessionStorage.removeItem('interestedfilters');
        }
        this.sendFilters();
    }

    disconnectedCallback() {
        // Going back with browser back or back button on mouse forces page refresh and a disconnect
        // Save filters on disconnect to exist only within the current browser tab
        sessionStorage.setItem('interestedfilters', JSON.stringify(this.filters));
    }

    renderedCallback() {
        this.setPreviousFiltersOnRefresh();
    }

    connectedCallback() {
        this.setColumns();
        refreshApex(this.wiredInterestedResourcesResult);
        this.getParams();
        this.updateURL();
    }
    getParams() {
        let parsed_params = getParametersFromURL() ?? '';
        if (parsed_params.from == 'mine-varsler' && parsed_params.id != '') {
            this.goToRecordDetailsFromNotification(parsed_params.id);
        }
    }

    @track serviceResource;
    @wire(getServiceResource)
    wiredServiceresource(result) {
        if (result.data) {
            this.serviceResource = result.data;
        }
    }

    dataLoader = true;
    noInterestedResources = false;
    initialInterestedResources = [];
    @track records = [];
    @track allInterestedResourcesWired = [];
    wiredInterestedResourcesResult;
    @track test = true;
    @wire(getInterestedResources)
    wiredInterestedResources(result) {
        this.wiredInterestedResourcesResult = result;
        if (result.data) {
            this.noInterestedResources = this.allInterestedResourcesWired.length === 0;
            this.error = undefined;
            this.allInterestedResourcesWired = [...result.data];
            this.noInterestedResources = this.allInterestedResourcesWired.length === 0;
            getContactId({}).then((contactId) => {
                this.userContactId = contactId;

                getMyThreads().then((result) => {
                    var thread = [];
                    thread = result;
                    var map = new Map();
                    thread.forEach((t) => {
                        map.set(t.CRM_Related_Object__c, t.HOT_Thread_read_by__c);
                    });
                    this.allInterestedResourcesWired = this.allInterestedResourcesWired.map((appointment) => {
                        let threadId;
                        if (appointment.Status__c == 'Assigned' || appointment.Status__c == 'Tildelt') {
                            threadId = appointment.ServiceAppointment__c;
                        } else {
                            threadId = appointment.Id;
                        }
                        let status = 'noThread';
                        if (map.has(threadId)) {
                            const readBy = map.get(threadId);
                            if (typeof readBy === 'string' && readBy.includes(this.userContactId)) {
                                status = 'false';
                            } else {
                                status = 'true';
                            }
                        }
                        return {
                            ...appointment,
                            IsUnreadMessage: status,
                            startAndEndDateWeekday:
                                formatDatetimeinterval(
                                    appointment.ServiceAppointmentStartTime__c,
                                    appointment.ServiceAppointmentEndTime__c
                                ) +
                                ' ' +
                                getDayOfWeek(appointment.ServiceAppointmentStartTime__c),
                            statusMobile: 'Status: ' + appointment.Status__c
                        };
                    });
                    let tempRecords = [];
                    for (let record of this.allInterestedResourcesWired) {
                        tempRecords.push(formatRecord(Object.assign({}, record), this.datetimeFields));
                    }
                    this.records = tempRecords;
                    this.initialInterestedResources = [...this.records];

                    this.refresh();
                    this.dataLoader = false;
                });
            });
        } else if (result.error) {
            this.dataLoader = false;
            this.error = result.error;
            this.allInterestedResourcesWired = undefined;
        }
    }

    refresh() {
        let filterFromSessionStorage = JSON.parse(sessionStorage.getItem('interestedSessionFilter'));
        this.filters = filterFromSessionStorage === null ? defaultFilters() : filterFromSessionStorage;
        //this.goToRecordDetails({ detail: { Id: this.recordId } });
        //this.sendRecords();
        this.sendFilters();
        this.applyFilter({ detail: { filterArray: this.filters, setRecords: true } });
    }

    datetimeFields = [
        {
            name: 'StartAndEndDate',
            type: 'datetimeinterval',
            start: 'ServiceAppointmentStartTime__c',
            end: 'ServiceAppointmentEndTime__c'
        },
        { name: 'WorkOrderCanceledDate__c', type: 'date' },
        { name: 'HOT_ReleaseDate__c', type: 'date' },
        { name: 'AppointmentDeadlineDate__c', type: 'date' }
    ];
    hasFocused = false;
    handleKeyDown(event) {
        const focusables = this._getFocusableElements();
        const firstEl = focusables[0];
        const lastEl = focusables[focusables.length - 1];
        const active = this.template.activeElement;

        if (event.key === 'Tab') {
            if (event.shiftKey) {
                // Shift + Tab
                if (active === firstEl) {
                    event.preventDefault();
                    lastEl.focus();
                }
            } else {
                // Tab
                if (active === lastEl) {
                    event.preventDefault();
                    firstEl.focus();
                }
            }
        }

        // Escape lukker modal
        if (event.key === 'Escape') {
            this.handleClose();
        }
    }

    // Hent alle tabbable elementer i modal
    _getFocusableElements() {
        const modal = this.template.querySelector('.modal-container');
        if (!modal) return [];
        return Array.from(
            modal.querySelectorAll('button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])')
        );
    }

    showServiceAppointmentDetails() {
        this.showServiceAppointmentDetailsModal = true;
        document.body.style.overflow = 'hidden';
        // Vent til DOM er oppdatert før vi fokuserer første element
        setTimeout(() => {
            const firstFocusable = this._getFocusableElements()[0];
            if (firstFocusable) {
                firstFocusable.focus();
                this.hasFocused = true;
            }
        }, 0);
    }

    showServiceAppointmentDetailsModal = false;

    @track interestedResource;
    isDetails = false;
    isSeries = false;
    showTable = true;
    goToRecordDetails(result) {
        this.hasAccess = true;
        this.interestedResource = undefined;
        let recordId = result.detail.Id;
        this.recordId = recordId;
        this.isDetails = !!this.recordId;
        for (let interestedResource of this.records) {
            if (recordId === interestedResource.Id) {
                this.interestedResource = interestedResource;
                let relaseDateTimeFormatted = new Date(
                    this.interestedResource.ServiceAppointment__r.HOT_ReleaseDate__c
                );
                this.interestedResource.releasedate =
                    relaseDateTimeFormatted.getDate() +
                    '.' +
                    (relaseDateTimeFormatted.getMonth() + 1) +
                    '.' +
                    relaseDateTimeFormatted.getFullYear();
                if (this.interestedResource.releasedate.includes('NaN')) {
                    this.interestedResource.releasedate = '';
                }

                this.interestedResource.weekday = getDayOfWeek(this.interestedResource.ServiceAppointmentStartTime__c);
            }
        }

        this.isNotRetractable = this.interestedResource?.Status__c !== 'Påmeldt';
        this.updateURL();

        this.showServiceAppointmentDetails();
        refreshApex(this.wiredInterestedResourcesResult);
    }

    goToRecordDetailsFromNotification(saId) {
        checkAccessToSA({ saId: saId }).then((result) => {
            if (result != false) {
                getInterestedResourceDetails({ recordId: saId }).then((result) => {
                    this.interestedResource = result;
                    this.isDetails = true;
                    this.isNotRetractable = this.interestedResource?.Status__c !== 'Påmeldt';
                    this.interestedResource.weekday = getDayOfWeek(
                        this.interestedResource.ServiceAppointmentStartTime__c
                    );
                    let startTimeFormatted = new Date(result.ServiceAppointmentStartTime__c);
                    let endTimeFormatted = new Date(result.ServiceAppointmentEndTime__c);
                    this.interestedResource.StartAndEndDate =
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
                    let relaseDateTimeFormatted = new Date(
                        this.interestedResource.ServiceAppointment__r.HOT_ReleaseDate__c
                    );
                    this.interestedResource.releasedate =
                        relaseDateTimeFormatted.getDate() +
                        '.' +
                        (relaseDateTimeFormatted.getMonth() + 1) +
                        '.' +
                        relaseDateTimeFormatted.getFullYear();
                    if (this.interestedResource.releasedate.includes('NaN')) {
                        this.interestedResource.releasedate = '';
                    }
                    let DeadlineDateTimeFormatted = new Date(this.interestedResource.AppointmentDeadlineDate__c);
                    this.interestedResource.AppointmentDeadlineDate__c =
                        DeadlineDateTimeFormatted.getDate() +
                        '.' +
                        (DeadlineDateTimeFormatted.getMonth() + 1) +
                        '.' +
                        DeadlineDateTimeFormatted.getFullYear();
                    if (this.interestedResource.AppointmentDeadlineDate__c.includes('NaN')) {
                        this.interestedResource.AppointmentDeadlineDate__c = '';
                    }
                    this.hasAccess = true;
                    this.showServiceAppointmentDetails();
                });
            } else {
                this.showServiceAppointmentDetails();
                this.hasAccess = false;
            }
        });
    }

    @api recordId;
    updateURL() {
        let baseURL =
            window.location.protocol + '//' + window.location.host + window.location.pathname + '?list=interested';
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
        return { id: recordIdToReturn, tab: 'interested' };
    }
    filteredRecordsLength = 0;
    noFilteredRecords = false;
    @api
    applyFilter(event) {
        let setRecords = event.detail.setRecords;
        this.filters = event.detail.filterArray;
        sessionStorage.setItem('interestedSessionFilter', JSON.stringify(this.filters));
        let filteredRecords = [];
        let records = this.initialInterestedResources;
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
    isNotRetractable = false;
    retractInterest() {
        retractInterest({ interestedResourceId: this.interestedResource.Id }).then(() => {
            refreshApex(this.wiredInterestedResourcesResult);
            this.interestedResource.Status__c = 'Tilbaketrukket påmelding';
            let newNumberOfInterestedResources = Number(this.interestedResource.NumberOfInterestedResources__c) - 1;
            this.interestedResource.NumberOfInterestedResources__c = newNumberOfInterestedResources;
            this.isNotRetractable = true;
        });
    }
    closeModal() {
        this.showServiceAppointmentDetailsModal = false;
        document.body.style.overflow = '';
        this.isGoToThreadButtonDisabled = false;
        this.recordId = undefined;
        this.updateURL();
    }
    navigateToThread(recordId) {
        const baseUrl = '/samtale-frilans';
        const attributes = `recordId=${recordId}&from=mine-oppdrag&list=interested&interestedRecordId=${this.interestedResource.Id}`;
        const url = `${baseUrl}?${attributes}`;

        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: url
            }
        });
    }
    goToInterestedResourceThread() {
        this.isGoToThreadButtonDisabled = true;
        if (
            this.interestedResource.Status__c != 'Assigned' &&
            this.interestedResource.Status__c != 'Tildelt' &&
            this.interestedResource.Status__c != 'Reserved' &&
            this.interestedResource.Status__c != 'Reservert'
        ) {
            getThreadDispatcherId({ interestedResourceId: this.interestedResource.Id }).then((result) => {
                if (result != '') {
                    this.threadId = result;
                    this.navigateToThread(this.threadId);
                } else {
                    createThreadInterpreter({ recordId: this.interestedResource.Id })
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
        } else {
            getThreadDispatcherIdSA({ saId: this.interestedResource.ServiceAppointment__c }).then((result) => {
                if (result != '') {
                    this.threadId = result;
                    this.navigateToThread(this.threadId);
                } else {
                    createThreadInterpreter({ recordId: this.interestedResource.ServiceAppointment__c })
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
    }
    get appointmentNumber() {
        return this.interestedResource?.AppointmentNumber__c || '';
    }

    get subject() {
        return this.interestedResource?.ServiceAppointmentFreelanceSubject__c || '';
    }

    get time() {
        return `${this.interestedResource?.weekday || ''} ${this.interestedResource?.StartAndEndDate || ''}`.trim();
    }

    get address() {
        return this.interestedResource?.ServiceAppointmentAddress__c || '';
    }

    get workType() {
        return this.interestedResource?.WorkTypeName__c || '';
    }

    get assignmentType() {
        return this.interestedResource?.AssignmentType__c || '';
    }

    get status() {
        return this.interestedResource?.Status__c || '';
    }

    get numberOfResources() {
        return this.interestedResource?.NumberOfInterestedResources__c ?? '';
    }

    get releaseDate() {
        return this.interestedResource?.releasedate || '';
    }

    get releasedBy() {
        return this.interestedResource?.ServiceAppointment__r?.HOT_ReleasedBy__c || '';
    }

    get deadline() {
        return this.interestedResource?.AppointmentDeadlineDate__c || '';
    }

    get region() {
        return this.interestedResource?.AppointmentServiceTerritory__c || '';
    }

    get ownerName() {
        return this.interestedResource?.ServiceAppointment__r?.HOT_Request__r?.OwnerName__c || '';
    }

    get canceledDate() {
        return this.interestedResource?.WorkOrderCanceledDate__c || '';
    }

    get terms() {
        return this.interestedResource?.HOT_TermsOfAgreement__c || '';
    }
}
