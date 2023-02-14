import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getMyThreads from '@salesforce/apex/HOT_ThreadListController.getMyThreads';
import getContactId from '@salesforce/apex/HOT_MessageHelper.getUserContactId';
import { refreshApex } from '@salesforce/apex';
import HOT_DispatcherConsoleOverride from '@salesforce/resourceUrl/HOT_DispatcherConsoleOverride';

export default class Hot_threadList extends NavigationMixin(LightningElement) {
    userContactId;
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
        }
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
            svg: true
        }
    ];
    @track tabs = [
        { name: 'mythreads', label: 'Samtaler med formidler', selected: true },
        { name: 'interpreterthreads', label: 'Samtaler tolk-bruker', selected: false }
    ];

    @track tabMap = {
        mythreads: true,
        interpreterthreads: false
    };

    setActiveTabMobile(event) {
        this.setActiveTab({ target: { dataset: { id: event.detail.name } } });
    }

    setActiveTab(event) {
        this.updateTab(event);
    }
    updateTab(event) {
        for (let tab of this.tabs) {
            tab.selected = false;
            this.tabMap[tab.name] = false;
            if (tab.name === event.target.dataset.id) {
                tab.selected = true;
                this.activeTab = tab.name;
                this.tabMap[tab.name] = true;
                if (this.activeTab == 'mythreads') {
                    this.showMythreads = true;
                    this.showInterpreterthreads = false;
                } else {
                    this.showMythreads = false;
                    this.showInterpreterthreads = true;
                }
            }
        }
        this.updateTabStyle();
    }
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
    @track unmappedThreads;
    @track threads;
    @track unmappedInterpreterThreads;
    showMythreads = true;
    showInterpreterthreads = false;
    noThreads = false;
    noInterpreterThreads = false;
    wiredThreadsResult;
    @wire(getMyThreads)
    wiredThreads(result) {
        this.wiredThreadsResult = result;
        if (result.data) {
            getContactId({})
                .then((contactId) => {
                    this.userContactId = contactId;
                    this.unmappedThreads = [];
                    this.threads = [];
                    this.unmappedInterpreterThreads = [];
                    result.data.forEach((element) => {
                        if (element.CRM_Type__c == 'HOT_BRUKER-TOLK') {
                            this.unmappedInterpreterThreads.push(element);
                        }
                        if (element.CRM_Type__c == 'HOT_BRUKER-FORMIDLER') {
                            this.unmappedThreads.push(element);
                        }
                    });
                    this.threads = this.unmappedThreads.map((x) => ({
                        ...x,
                        read: !String(x.HOT_Thread_read_by__c).includes(contactId) ? false : true
                    }));
                    this.interpreterThreads = this.unmappedInterpreterThreads.map((x) => ({
                        ...x,
                        read: !String(x.HOT_Thread_read_by__c).includes(contactId) ? false : true
                    }));
                    this.noThreads = this.threads.length === 0;
                    this.noInterpreterThreads = this.interpreterThreads.length === 0;
                })
                .catch((error) => {
                    //Apex error
                });
            this.activeTab = 'mythreads';
        }
    }

    get isMobile() {
        return window.screen.width < 576;
    }

    connectedCallback() {
        refreshApex(this.wiredThreadsResult);
    }
    renderedCallback() {
        this.updateTabStyle();
    }
    updateTabStyle() {
        this.template.querySelectorAll('button.tab').forEach((element) => {
            element.classList.remove('tab_active');
            if (element.dataset.id === this.activeTab) {
                element.classList.add('tab_active');
            }
        });
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
