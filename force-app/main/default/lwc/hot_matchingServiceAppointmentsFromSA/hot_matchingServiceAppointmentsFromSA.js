import { LightningElement, wire, track, api } from 'lwc';
import getServiceAppointments from '@salesforce/apex/HOT_IRRecordPageController.getRelevantServiceAppointments';
import { sortList } from 'c/sortController';

export default class Hot_matchingServiceAppointmentsFromSA extends LightningElement {
    @api recordId;
    @track showList = true;
    @track columns = [
        {
            label: 'Appointment Number',
            fieldName: 'ServiceAppointmentNumber',
            type: 'url',
            typeAttributes: { label: { fieldName: 'AppointmentNumber' }, target: '_blank' },
            sortable: true
        },
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
            label: 'Type',
            fieldName: 'HOT_AssignmentType__c',
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
    @track defaultSortDirection = 'asc';
    @track sortDirection = 'asc';
    @track sortedBy = 'EarliestStartTime';

    @track serviceAppointments;
    @wire(getServiceAppointments, { recordId: '$recordId' })
    wiredServiceAppointments(result) {
        if (result.data) {
            let tempServiceAppointments = [];
            result.data.forEach((record) => {
                let tempRecord = Object.assign({}, record);
                tempRecord.ServiceAppointmentNumber = '/' + tempRecord.Id;
                tempServiceAppointments.push(tempRecord);
            });
            if (tempServiceAppointments.length === 0) {
                this.showList = false;
            } else {
                this.serviceAppointments = tempServiceAppointments;
            }
        }
    }
    onHandleSort(event) {
        this.sortDirection = event.detail.sortDirection;
        this.sortedBy = event.detail.fieldName;
        this.serviceAppointments = sortList(this.serviceAppointments, this.sortedBy, this.sortDirection);
    }
}
