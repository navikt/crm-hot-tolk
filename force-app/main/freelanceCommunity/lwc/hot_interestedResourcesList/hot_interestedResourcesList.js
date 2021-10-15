import { LightningElement, wire, track, api } from 'lwc';
import getInterestedResources from '@salesforce/apex/HOT_InterestedResourcesListController.getInterestedResources';
import getServiceResource from '@salesforce/apex/HOT_Utility.getServiceResource';
import { refreshApex } from '@salesforce/apex';
import retractInterests from '@salesforce/apex/HOT_InterestedResourcesListController.retractInterests';
import addComment from '@salesforce/apex/HOT_InterestedResourcesListController.addComment';
import readComment from '@salesforce/apex/HOT_InterestedResourcesListController.readComment';
import { interestedResourceFieldLabels } from 'c/hot_fieldLabels';
import { formatRecord } from 'c/hot_recordDetails';
import { sortList, getMobileSortingOptions } from 'c/sortController';

var actions = [
    //{ label: 'Kommenter', name: 'comment' },
    { label: 'Detaljer', name: 'details' }
];

export default class Hot_interestedResourcesList extends LightningElement {
    @track columns = [
        {
            label: 'Start tid',
            fieldName: 'ServiceAppointmentStartTime__c',
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
            fieldName: 'ServiceAppointmentEndTime__c',
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
            fieldName: 'ServiceAppointmentCity__c',
            type: 'text',
            sortable: true
        },
        {
            label: 'Tema',
            fieldName: 'ServiceAppointmentFreelanceSubject__c',
            type: 'text',
            sortable: true
        },
        {
            label: 'Tolkemetode',
            fieldName: 'WorkTypeName__c',
            type: 'text',
            sortable: true
        },
        {
            label: 'Status',
            fieldName: 'Status__c',
            type: 'text',
            sortable: true
        },
        {
            label: 'Ny kommentar',
            fieldName: 'IsNewComment__c',
            type: 'boolean'
        },
        {
            type: 'action',
            typeAttributes: { rowActions: actions }
        }
    ];

    @track choices = [
        { name: 'Alle', label: 'Alle' },
        { name: 'Påmeldt', label: 'Påmeldt' },
        { name: 'Ikke tildelt deg', label: 'Ikke tildelt deg' },
        { name: 'Tilbaketrukket påmelding', label: 'Tilbaketrukket påmelding' },
        { name: 'Avlyst', label: 'Avlyst' },
        { name: 'Oppdrag tilbaketrukket', label: 'Oppdrag tilbaketrukket' },
        { name: 'Avlyst av tolk', label: 'Avlyst av tolk' }
    ];

    @track serviceResource;
    @wire(getServiceResource)
    wiredServiceresource(result) {
        if (result.data) {
            this.serviceResource = result.data;
        }
    }

    @track interestedResources;
    @track interestedResourcesFiltered;
    wiredInterestedResourcesResult;
    @wire(getInterestedResources)
    wiredInterestedResources(result) {
        this.wiredInterestedResourcesResult = result;
        if (result.data) {
            this.interestedResources = result.data;
            this.error = undefined;
            this.filterInterestedResources();
        } else if (result.error) {
            this.error = result.error;
            this.interestedResources = undefined;
        }
    }
    filterInterestedResources() {
        var tempInterestedResources = [];
        for (var i = 0; i < this.interestedResources.length; i++) {
            if (this.picklistValue === 'Alle') {
                tempInterestedResources.push(this.interestedResources[i]);
                // Covers statuses: 'Tildelt', 'Påmeldt', 'Ikke tildelt deg', 'Tilbaketrukket påmelding', 'Avlyst', 'Oppdrag tilbaketrukket' and 'Avlyst av tolk'
            } else if (this.picklistValue === this.interestedResources[i].Status__c) {
                tempInterestedResources.push(this.interestedResources[i]);
            }
        }
        this.interestedResourcesFiltered = tempInterestedResources;
    }

    @track picklistValue = 'Alle';
    handlePicklist(event) {
        this.picklistValue = event.detail.name;
        this.filterInterestedResources();
    }

    connectedCallback() {
        refreshApex(this.wiredInterestedResourcesResult);
    }

    //Sorting methods
    @track defaultSortDirection = 'asc';
    @track sortDirection = 'asc';
    @track sortedBy = 'ServiceAppointmentStartTime__c';

    get sortingOptions() {
        return getMobileSortingOptions(this.columns);
    }

    onHandleSort(event) {
        this.sortDirection = event.detail.sortDirection;
        this.sortedBy = event.detail.fieldName;
        this.interestedResources = sortList(this.interestedResources, this.sortedBy, this.sortDirection);
        this.filterInterestedResources();
    }

    //Row action methods
    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        switch (actionName) {
            case 'comment':
                this.openComments(row);
                break;
            case 'details':
                this.openDetails(row);
                break;
            default:
        }
    }

    @track appointmentNumber = 'Ingen detaljer';
    @track recordId;
    @track prevComments = ['Ingen tidligere kommentarer'];
    sendComment() {
        let interestedResourceId = this.recordId;
        var newComment = this.template.querySelector('.newComment').value;
        addComment({ interestedResourceId, newComment }).then(() => {
            refreshApex(this.wiredInterestedResourcesResult);
        });
        this.template.querySelector('.ReactModal__Overlay').classList.add('hidden');
    }

    @track deadlineDate;
    @track interestedResourceDetails;
    openDetails(row) {
        this.interestedResourceDetails = formatRecord(row, interestedResourceFieldLabels);
        let detailPage = this.template.querySelector('.ReactModal__Overlay');
        detailPage.classList.remove('hidden');
        detailPage.focus();

        this.recordId = row.Id;
        if (row['Comments__c'] != undefined) {
            this.prevComments = row.Comments__c.split('\n\n');
        } else {
            this.prevComments = '';
        }
        let interestedResourceId = this.recordId;
        readComment({ interestedResourceId }).then(() => {
            refreshApex(this.wiredInterestedResourcesResult);
        });
    }
    abortShowDetails() {
        this.template.querySelector('.ReactModal__Overlay').classList.add('hidden');
    }

    @track selectedRows = [];
    getSelectedName(event) {
        this.selectedRows = event.detail.selectedRows;
    }

    retractInterest() {
        if (this.selectedRows.length > 0) {
            let retractionIds = [];
            for (var i = 0; i < this.selectedRows.length; i++) {
                retractionIds.push(this.selectedRows[i].Id);
            }
            if (confirm('Er du sikker på at du vil tilbaketrekke interesse for valgte oppdrag?')) {
                retractInterests({ retractionIds }).then(() => {
                    refreshApex(this.wiredInterestedResourcesResult);
                });
            }
        } else {
            alert('Velg oppdrag du ønsker å tilbaketrekke interesse for, så trykk på knappen.');
        }
    }
}
