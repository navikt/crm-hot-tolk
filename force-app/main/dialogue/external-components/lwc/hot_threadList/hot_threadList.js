import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getMyThreads from '@salesforce/apex/HOT_ThreadListController.getMyThreads';
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

    iconByValue = {
        false: {
            icon: 'Information',
            fill: '',
            ariaLabel: 'Du har nye meldinger'
        },
        true: {
            icon: 'SuccessFilled',
            fill: 'Green',
            ariaLabel: 'Ingen nye meldinger'
        },
    };
    
    @track columns = [
        {
            label: 'Tema',
            name: 'HOT_Subject__c',
            type: 'text'
        },
        {
            label: 'Status',
            name: 'read',
            type: 'boolean',
            svg: true,
        },
    ];
        
    openThread(event) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: event.detail.Id,
                objectApiName: 'Thread__c',
                actionName: 'view'
            }
        });
    }

    @track threads = [];
    noThreads = false;
    wiredThreadsResult;
    @wire(getMyThreads)
    wiredThreads(result) {
        this.wiredThreadsResult = result;
        if (result.data) {
            this.threads = result.data.map(x => ({...x, read: x.CRM_Number_of_unread_Messages__c > 0 ? false : true}));
            this.noThreads = this.threads.length === 0;
        }
    }

    get isMobile() {
        return window.screen.width < 576;
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