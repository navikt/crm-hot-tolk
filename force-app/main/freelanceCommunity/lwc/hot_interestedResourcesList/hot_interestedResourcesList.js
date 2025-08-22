import { LightningElement, wire, track, api } from 'lwc';
import getInterestedResources from '@salesforce/apex/HOT_InterestedResourcesListController.getInterestedResources';
import getMyThreads from '@salesforce/apex/HOT_ThreadListController.getMyThreadsIR';
import getInterestedResourceDetails from '@salesforce/apex/HOT_InterestedResourcesListController.getInterestedResourceDetails';
import checkAccessToSA from '@salesforce/apex/HOT_InterestedResourcesListController.checkAccessToSA';
import { formatRecord, formatDatetimeinterval } from 'c/datetimeFormatterNorwegianTime';
import getContactId from '@salesforce/apex/HOT_MessageHelper.getUserContactId';
import getServiceResource from '@salesforce/apex/HOT_Utility.getServiceResource';
import { refreshApex } from '@salesforce/apex';
import { getParametersFromURL } from 'c/hot_URIDecoder';
import { columns, mobileColumns, iconByValue } from './columns';
import { defaultFilters, compare } from './filters';
import { getDayOfWeek } from 'c/hot_commonUtils';
import { NavigationMixin } from 'lightning/navigation';

import Hot_interestedResourcesListModal from 'c/hot_interestedResourcesListModal';

export default class Hot_interestedResourcesList extends NavigationMixin(LightningElement) {
    @track columns = [];
    @track filters = [];
    @track iconByValue = iconByValue;
    @track isGoToThreadButtonDisabled = false;
    @track isMobile;
    @track hasAccess = true;

    setColumns() {
        if (window.screen.width > 576) {
            this.columns = columns;
            this.isMobile = false;
        } else {
            this.columns = mobileColumns;
            this.isMobile = true;
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

    @track interestedResource;
    isDetails = false;
    isSeries = false;
    showTable = true;
    async goToRecordDetails(result) {
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

        await Hot_interestedResourcesListModal.open({
            size: 'small',
            interestedResource: this.interestedResource,
            isNotRetractable: this.isNotRetractable,
            serviceResource: this.serviceResource
        });
        refreshApex(this.wiredInterestedResourcesResult);
    }

    getModalSize() {
        return window.screen.width < 768 ? 'full' : 'small';
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
                    Hot_interestedResourcesListModal.open({
                        size: 'small',
                        description: 'Informasjon om oppdraget',
                        interestedResource: this.interestedResource,
                        isNotRetractable: this.isNotRetractable,
                        serviceResource: this.serviceResource,
                        hasAccess: true
                    });
                });
            } else {
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
}
