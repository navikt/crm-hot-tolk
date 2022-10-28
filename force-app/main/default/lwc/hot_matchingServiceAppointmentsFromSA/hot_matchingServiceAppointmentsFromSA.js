import { LightningElement, wire, track, api } from 'lwc';
import getServiceAppointments from '@salesforce/apex/HOT_ServiceAppointmentController.getServiceAppointments';

export default class Hot_matchingServiceAppointmentsFromSA extends LightningElement {
    @api recordId;
    @track showList = true;
    @track columns = [
        {
            label: 'Appointment Number',
            fieldName: 'SAppointmentNumber',
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
    @track serviceAppointments;
    @wire(getServiceAppointments, { recordId: '$recordId' })
    wiredServiceAppointments(result) {
        if (result.data) {
            let tempServiceAppointments = [];
            result.data.forEach((record) => {
                let tempRecord = Object.assign({}, record);
                tempRecord.SAppointmentNumber = '/' + tempRecord.Id;
                tempServiceAppointments.push(tempRecord);
            });
            this.serviceAppointments = tempServiceAppointments;
        }
    }
}
