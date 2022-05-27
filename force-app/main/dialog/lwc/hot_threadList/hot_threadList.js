import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getMyThreads from '@salesforce/apex/HOT_ThreadListController.getMyThreads';
import openThread from '@salesforce/apex/HOT_ThreadListController.openThread';
import { refreshApex } from '@salesforce/apex';

export default class Hot_threadList extends NavigationMixin(LightningElement) {
    breadcrumbs = [ 
        {
            label: 'Tolketjenesten',
            href: ''
        },
        {
            label: 'Mine samtaler',
            href: 'mine-samtaler'
        }
    ];
    @track columns = [
        /*{
            label: '',
            fieldName: 'HOT_Subject__c',
            type: 'text',
            sortable: true,
        },
        {
            label: 'Lest',
            fieldName: 'CRM_Number_of_unread_Messages__c',
            type: 'boolean',
            sortable: true,
        },*/
        {
            label: 'Thread Name',
            fieldName: 'Name',
            type: 'text'
        },
        {
            type: 'action',
            typeAttributes: { rowActions: this.getRowActions }
        }
    ];
    mobileColumns = [
        "'Tittel'"
        //"'Lest'"
    ];

    getRowActions(doneCallback) {
        let actions = [];
        actions.push({ label: 'Åpne samtale', name: 'open thread' });
        doneCallback(actions);
    }

    //Sorting methods
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
    }

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
        console.log('wiredThreads');
        if (result.data) {
            console.log(JSON.stringify(result.data));
            this.threads = result.data;
        }
    }

    connectedCallback() {
        refreshApex(this.wiredThreadsResult);
    }
    
    goBack() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                pageName: 'home'
            }
        });
    }
}