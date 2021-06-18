import getServiceAppointments from '@salesforce/apex/HOT_ServiceAppointmentWageClaimService.getServiceAppointments';
import assign from '@salesforce/apex/HOT_ServiceAppointmentWageClaimService.assign';
import { LightningElement, wire, track, api } from 'lwc';
import { sortList, getMobileSortingOptions } from 'c/sortController';

var actions = [{ label: 'Tildel', name: 'assign' }];
export default class Hot_matchingServiceAppointments extends LightningElement {
    @api recordId;

    @track columns = [
        {
            label: 'Oppdrag',
            fieldName: 'AppointmentNumber',
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
        console.log(JSON.stringify(result));
        console.log('derp');
        if (result.data) {
            this.serviceAppointments = result.data;
            //console.log(this.serviceAppointments.length);
        }
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        switch (actionName) {
            case 'assign':
                this.assignResourceToServiceAppointment(row.Id);
                break;
            default:
        }
    }
    assignResourceToServiceAppointment(serviceAppointmentId) {
        assign({ wageClaimId: this.recordId, serviceAppointmentId: serviceAppointmentId });
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
}
