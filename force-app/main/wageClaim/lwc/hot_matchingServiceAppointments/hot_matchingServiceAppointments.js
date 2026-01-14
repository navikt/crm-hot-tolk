import getServiceAppointments from '@salesforce/apex/HOT_WageClaimService.getServiceAppointments';
import assign from '@salesforce/apex/HOT_WageClaimService.assign';
import { LightningElement, wire, track, api } from 'lwc';
import { sortList, getMobileSortingOptions } from 'c/sortController';

var actions = [{ label: 'Reserver', name: 'assign' }];
export default class Hot_matchingServiceAppointments extends LightningElement {
    @api recordId;
    isLoaded = false;

    @track columns = [
        {
            label: 'Oppdrag',
            fieldName: 'ServiceAppointmentName',
            type: 'url',
            typeAttributes: { label: { fieldName: 'AppointmentNumber' }, target: '_blank' },
            sortable: true
        },
        {
            label: 'Start tid',
            fieldName: 'SchedStartTime',
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
            fieldName: 'SchedEndTime',
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
            label: 'Tolkemetode',
            fieldName: 'HOT_WorkTypeName__c',
            type: 'text',
            sortable: true
        },
        {
            label: 'Region',
            fieldName: 'HOT_ServiceTerritoryName__c',
            type: 'text',
            sortable: true
        },
        {
            label: 'Oppmøte/Skjerm',
            fieldName: 'HOT_InterpretationType__c',
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

    @track serviceAppointments;
    @wire(getServiceAppointments, { wageClaimId: '$recordId' })
    wiredServiceAppointments(result) {
        if (result.data) {
            let tempServiceAppointments = [];
            result.data.forEach((record) => {
                let tempRecord = Object.assign({}, record);
                tempRecord.ServiceAppointmentName = '/' + tempRecord.Id;
                tempServiceAppointments.push(tempRecord);
            });
            this.serviceAppointments = tempServiceAppointments;
            this.isLoaded = true;
        }
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        if (actionName == 'assign') {
            this.assignResourceToServiceAppointment(row.Id);
        }
    }
    @track showList = true;
    @track assigned = false;
    @track loading = false;
    serviceAppointmentId = null;
    @track isError = false;
    @track errorMessage = '';
    assignResourceToServiceAppointment(serviceAppointmentId) {
        this.showList = false;
        this.loading = true;
        this.serviceAppointmentId = serviceAppointmentId;
        assign({ wageClaimId: this.recordId, serviceAppointmentId: serviceAppointmentId })
            .then((result) => {
                this.assigned = true;
                this.showList = false;
                this.loading = false;
            })
            .catch((error) => {
                console.log(JSON.stringify(error));
                this.errorMessage = error.body.pageErrors[0].message;
                this.isError = true;
                this.showList = false;
                this.loading = false;
            });
    }
    reset() {
        this.showList = true;
        this.isError = false;
        this.errorMessage = '';
    }

    //Sorting methods
    @track defaultSortDirection = 'asc';
    @track sortDirection = 'desc';
    @track sortedBy = 'HOT_ReleaseDate__c';

    mobileSortingDefaultValue = '{"fieldName": "HOT_ReleaseDate__c", "sortDirection": "desc"} ';
    get sortingOptions() {
        return getMobileSortingOptions(this.columns);
    }

    handleMobileSorting(event) {
        let value = JSON.parse(event.detail.value);
        this.sortDirection = value.sortDirection;
        this.sortedBy = value.fieldName;
        this.serviceAppointments = sortList(this.serviceAppointments, this.sortedBy, this.sortDirection);
    }
    onHandleSort(event) {
        this.sortDirection = event.detail.sortDirection;
        this.sortedBy = event.detail.fieldName;
        this.serviceAppointments = sortList(this.serviceAppointments, this.sortedBy, this.sortDirection);
    }

    goToServiceAppointment() {
        window.location.pathname = '/' + this.serviceAppointmentId;
    }
}
