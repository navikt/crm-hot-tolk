import { LightningElement, wire, track, api } from 'lwc';

export default class Hot_matchingServiceAppointments extends LightningElement {
    @track columns = [
        {
            label: 'Start tid',
            fieldName: 'SchedStartDate',
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
            fieldName: 'SchedEndDate',
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
            fieldName: 'WorkTypeId',
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
    /*
    @wire(getServiceResource)
    wiredServiceresource(result) {
        if (result.data) {
            this.serviceResource = result.data;
            //console.log(JSON.stringify(this.serviceResource));
        }
    }
    */
}
