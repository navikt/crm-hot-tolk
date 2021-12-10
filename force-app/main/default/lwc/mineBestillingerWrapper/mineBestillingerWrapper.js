import { LightningElement, track, wire } from 'lwc';
import getRequestList from '@salesforce/apex/HOT_RequestListContoller.getRequestList';

export default class MineBestillingerWrapper extends LightningElement {
    @track records = [];
    connectedCallback() {
        let date = new Date();
        date = date.toDateString();
        this.records = [
            {
                Id: 0,
                StartDate: date,
                Status: 'S',
                Subject: 'Superkult tema',
                IsSeries: 'S'
            }
        ];
    }

    @track columns = [
        {
            name: 'Name',
            type: 'String'
        },
        {
            name: 'UserName__c',
            type: 'String'
        },
        {
            name: 'Status__c',
            type: 'String'
        }
    ];

    @track requests = [];
    wiredRequestsResult;
    @wire(getRequestList)
    wiredRequest(result) {
        this.wiredRequestsResult = result;
        if (result.data) {
            this.requests = [...result.data];
            this.template.querySelector('c-record-list').showRecords(this.requests);
        }
    }

    goToRecordDetails(result) {
        console.log('Navigating to: ' + result.detail);
    }

    filterChoices = [
        {
            name: 'status',
            label: 'Status',
            type: 'checkbox',
            choices: [
                {
                    name: 'choice 1',
                    label: 'Choice one'
                }
            ]
        },
        {
            name: 'datetime',
            label: 'tidspunkt',
            type: 'datetime',
            choices: [
                {
                    name: 'startTime',
                    label: 'Fra dato'
                },
                {
                    name: 'endTime',
                    label: 'Til dato'
                }
            ]
        }
    ];
}
