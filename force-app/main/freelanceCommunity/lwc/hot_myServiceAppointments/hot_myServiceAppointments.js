import { LightningElement, wire, track, api } from 'lwc';
import getMyServiceAppointments from '@salesforce/apex/HOT_MyServiceAppointmentListController.getMyServiceAppointments';
import getServiceResource from '@salesforce/apex/HOT_Utility.getServiceResource';
import { myServiceAppointmentFieldLabels } from 'c/hot_fieldLabels';
import { formatRecord } from 'c/hot_recordDetails';
import { sortList, getMobileSortingOptions } from 'c/sortController';

var actions = [{ label: 'Detaljer', name: 'details' }];

export default class Hot_myServiceAppointments extends LightningElement {
    @track columns = [
        {
            label: 'Start tid',
            fieldName: 'EarliestStartTime',
            type: 'date',
            sortable: true,
            typeAttributes: {
                day: 'numeric',
                month: 'numeric',
                year: 'numeric',
                hour: '2-digit',
                minute: '2-digit',
                hour12: false
            }
        },
        {
            label: 'Slutt tid',
            fieldName: 'DueDate',
            type: 'date',
            sortable: true,
            typeAttributes: {
                day: 'numeric',
                month: 'numeric',
                year: 'numeric',
                hour: '2-digit',
                minute: '2-digit',
                hour12: false
            }
        },
        {
            label: 'Poststed',
            fieldName: 'City',
            type: 'text',
            sortable: true
        },
        {
            label: 'Tema',
            fieldName: 'Subject',
            type: 'text',
            sortable: true
        },
        {
            label: 'Tolkemetode',
            fieldName: 'HOT_WorkTypeName__c',
            type: 'text',
            sortable: true
        },
        {
            label: 'Status',
            fieldName: 'Status',
            type: 'text',
            sortable: true
        },
        {
            type: 'action',
            typeAttributes: { rowActions: actions }
        }
    ];

    @track choices = [
        { name: 'Alle', label: 'Alle' },
        { name: 'Fremtidige', label: 'Fremtidige' },
        { name: 'Tildelt', label: 'Tildelt' },
        { name: 'Dekket', label: 'Dekket' }
    ];

    @track serviceResource;
    @wire(getServiceResource)
    wiredServiceresource(result) {
        if (result.data) {
            this.serviceResource = result.data;
        }
    }

    @track myServiceAppointments;
    @track myServiceAppointmentsFiltered;
    wiredMyServiceAppointmentsResult;
    @wire(getMyServiceAppointments)
    wiredMyServiceAppointments(result) {
        this.wiredMyServiceAppointmentsResult = result;
        if (result.data) {
            this.myServiceAppointments = result.data;
            this.error = undefined;
            this.filterServiceAppointments();
        } else if (result.error) {
            this.error = result.error;
            this.myServiceAppointments = undefined;
        }
    }

    filterServiceAppointments() {
        var tempServiceAppointments = [];
        for (var i = 0; i < this.myServiceAppointments.length; i++) {
            let status = this.myServiceAppointments[i].Status;
            if (this.picklistValue === 'Alle') {
                tempServiceAppointments.push(this.myServiceAppointments[i]);
            } else if (
                this.picklistValue === 'Fremtidige' &&
                status !== 'Avlyst' &&
                this.myServiceAppointments[i].SchedEndTime > new Date().toISOString().substring(0, 10)
            ) {
                tempServiceAppointments.push(this.myServiceAppointments[i]);
                // Covers 'Tildelt' and 'Dekket'
            } else if (this.picklistValue === status) {
                tempServiceAppointments.push(this.myServiceAppointments[i]);
            }
        }
        this.myServiceAppointmentsFiltered = tempServiceAppointments;
    }

    @track picklistValue = 'Alle';
    handlePicklist(event) {
        this.picklistValue = event.detail.name;
        this.filterServiceAppointments();
    }

    //Sorting methods
    @track defaultSortDirection = 'asc';
    @track sortDirection = 'asc';
    @track sortedBy = 'EarliestStartTime';

    get sortingOptions() {
        return getMobileSortingOptions(this.columns);
    }

    onHandleSort(event) {
        this.sortDirection = event.detail.sortDirection;
        this.sortedBy = event.detail.fieldName;
        this.myServiceAppointments = sortList(this.myServiceAppointments, this.sortedBy, this.sortDirection);
        this.filterServiceAppointments();
    }

    //Row action methods
    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        switch (actionName) {
            case 'details':
                this.showDetails(row);
                break;
            default:
        }
    }

    @track recordId;
    @track serviceAppointmentDetails;
    showDetails(row) {
        this.recordId = row.HOT_IsFortyfiveDaysOld ? null : row.Id;
        this.serviceAppointmentDetails = formatRecord(row, myServiceAppointmentFieldLabels);
        let detailPage = this.template.querySelector('.detailPage');
        detailPage.classList.remove('hidden');
        detailPage.focus();
    }

    abortShowDetails() {
        this.template.querySelector('.detailPage').classList.add('hidden');
    }
}
