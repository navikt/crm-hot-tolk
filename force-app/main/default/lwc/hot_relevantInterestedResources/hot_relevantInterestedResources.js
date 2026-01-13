import { LightningElement, api, wire, track } from 'lwc';
import getRelevantInterestedResources from '@salesforce/apex/HOT_IRRecordPageController.getRelevantInterestedResources';
import { sortList } from 'c/sortController';

export default class Hot_relevantInterestedResources extends LightningElement {
    defaultSortDirection = 'asc';
    sortDirection = 'asc';
    sortedBy = 'ServiceResourceName';
    noResources = false;
    @api recordId;
    columns = [
        {
            label: 'Appointment Number',
            fieldName: 'ServiceAppointmentNumber',
            type: 'url',
            typeAttributes: { label: { fieldName: 'AppointmentNumber' }, target: '_blank' },
            sortable: false
        },
        {
            label: 'Navn',
            fieldName: 'ServiceResourceName',
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
            label: 'Opprettet',
            fieldName: 'CreatedDate',
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
        }
    ];
    interestedResources;
    @wire(getRelevantInterestedResources, { recordId: '$recordId' })
    wiredInterestedResources(result) {
        if (result.data) {
            let tempInterestedResources = [];
            result.data.forEach((record) => {
                let tempRecord = Object.assign({}, record);
                tempRecord.ServiceAppointmentNumber = '/' + record.ServiceAppointment__r.Id;

                tempRecord.EarliestStartTime = record.ServiceAppointment__r.EarliestStartTime;

                tempRecord.DueDate = record.ServiceAppointment__r.DueDate;

                tempRecord.ServiceResourceName = record.ServiceResource__r.Name;

                tempRecord.Status = record.Status__c;

                tempRecord.AppointmentNumber = record.ServiceAppointment__r.AppointmentNumber;

                tempInterestedResources.push(tempRecord);
            });
            if (tempInterestedResources.length === 0) {
                this.noResources = true;
            } else {
                this.interestedResources = tempInterestedResources;
            }
        }
    }
    onHandleSort(event) {
        this.sortDirection = event.detail.sortDirection;
        this.sortedBy = event.detail.fieldName;
        this.interestedResources = sortList(this.interestedResources, this.sortedBy, this.sortDirection);
    }
}
