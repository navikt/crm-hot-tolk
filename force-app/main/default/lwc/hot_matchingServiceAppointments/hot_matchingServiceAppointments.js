import getServiceAppointments from '@salesforce/apex/HOT_ServiceAppointmentWageClaimService.getServiceAppointments';
import { LightningElement, wire, track, api } from 'lwc';
import { sortList, getMobileSortingOptions } from 'c/sortController';

export default class Hot_matchingServiceAppointments extends LightningElement {
    @api recordId;

    @track columns = [
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
            label: 'Status',
            fieldName: 'Status',
            type: 'text',
            sortable: true
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
