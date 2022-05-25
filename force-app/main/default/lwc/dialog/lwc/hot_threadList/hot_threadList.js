import { LightningElement, wire, track } from 'lwc';
import getMyThreads from '@salesforce/apex/HOT_ThreadListController.getMyThreads';
import openThread from '@salesforce/apex/HOT_ThreadListController.openThread';

export default class Hot_threadList extends LightningElement {
    @track columns = [
        {
            label: 'Tittel',
            fieldName: 'HOT_Subject__c',
            type: 'text',
            sortable: true,
        },
        /*{ CRM_Read_By_Nav__c is on Message object
            label: 'Lest',
            fieldName: 'CRM_Read_By_Nav__c',
            type: 'boolean',
            sortable: true,
        },*/
        {
            type: 'action',
            typeAttributes: { rowActions: this.getRowActions }
        }
    ];
    mobileColumns = [
        "'Tittel'",
        "'Lest'"
    ];

    getRowActions(doneCallback) {
        let actions = [];
        actions.push({ label: 'Åpne samtale', name: 'open thread' });
        doneCallback(actions);
    }

   /* //Sorting methods
    @track defaultSortDirection = 'asc';
    @track sortDirection = 'asc';
    @track sortedBy = 'StartTime__c';

    get sortingOptions() {
        return getMobileSortingOptions(this.columns);
    }

    onHandleSort(event) {
        this.sortDirection = event.detail.sortDirection;
        this.sortedBy = event.detail.fieldName;
        this.threads = sortList(this.threads, this.sortedBy, this.sortDirection);
    }*/

    //Row action methods
    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        if (actionName == 'open thread') {
            this.openThread(row);
        }
    }
    openThread(row) {}

    @track threads = [];
    wiredThreadsResult;
    @wire(getMyThreads)
    wiredThreads(result) {
        this.wiredThreadsResult = result;
        if (result.data) {
            this.threads = result.data;
        }
    }

    connectedCallback() {
        refreshApex(this.wiredThreadsResult);
    }
}