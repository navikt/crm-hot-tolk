import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getMyThreads from '@salesforce/apex/HOT_ThreadListController.getMyThreads';
import getContactId from '@salesforce/apex/HOT_MessageHelper.getUserContactId';
import { refreshApex } from '@salesforce/apex';
import HOT_DispatcherConsoleOverride from '@salesforce/resourceUrl/HOT_DispatcherConsoleOverride';

export default class Hot_threadList extends NavigationMixin(LightningElement) {
    userContactId;
    @track isMobile;
    @track columns = [];
    setTable() {
        if (window.screen.width > 576) {
            this.isMobile = false;
        } else {
            this.isMobile = true;
        }
    }
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
        },
        {
            label: 'Siste melding',
            name: 'lastMessage',
            type: 'text'
        },
        {
            label: 'Oppdrags start',
            name: 'appointmentStart',
            type: 'text'
        }
    ];
    @track mobileColumns = [
        {
            label: 'Tema',
            name: 'HOT_Subject__c',
            type: 'text',
            bold: false
        },
        {
            label: 'Status',
            name: 'read',
            type: 'boolean',
            svg: true,
            bold: false
        },
        {
            label: 'Siste melding',
            name: 'lastMessage',
            type: 'text',
            bold: true
        },
        {
            label: 'Oppdrags start',
            name: 'appointmentStart',
            type: 'text',
            bold: true
        }
    ];
    @track tabs = [
        { name: 'mythreads', label: 'Med formidler', selected: true, hasUnread: false },
        { name: 'interpreterthreads', label: 'Med tolk', selected: false, hasUnread: false }
    ];

    @track tabMap = {
        mythreads: true,
        interpreterthreads: false
    };

    formatDateTime(date) {
        let unformatted = new Date(date);
        let formattedTime =
            ('0' + unformatted.getDate()).slice(-2) +
            '.' +
            ('0' + (unformatted.getMonth() + 1)).slice(-2) +
            '.' +
            unformatted.getFullYear() +
            ', Kl ' +
            ('0' + unformatted.getHours()).slice(-2) +
            ':' +
            ('0' + unformatted.getMinutes()).slice(-2);
        if (formattedTime.includes('NaN')) {
            formattedTime = '';
        }
        return formattedTime;
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
                    this.showOrderthreads = false;
                    this.showOrdererUserThreads = false;
                }
                if (this.activeTab == 'interpreterthreads') {
                    this.showMythreads = false;
                    this.showInterpreterthreads = true;
                    this.showOrderthreads = false;
                    this.showOrdererUserThreads = false;
                }
                if (this.activeTab == 'orderThreads') {
                    this.showMythreads = false;
                    this.showInterpreterthreads = false;
                    this.showOrderthreads = true;
                    this.showOrdererUserThreads = false;
                }
                if (this.activeTab == 'ordererUserThreads') {
                    this.showMythreads = false;
                    this.showInterpreterthreads = false;
                    this.showOrderthreads = false;
                    this.showWageClaimthreads = false;
                    this.showOrdererUserThreads = true;
                    this.showInterpreterInterpreterThreads = false;
                }
            }
        }
        sessionStorage.setItem('activeMessageList', this.activeTab);
        this.updateTabStyle();
    }
    openThread(event) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: event.detail.Id,
                objectApiName: 'Thread__c',
                actionName: 'view'
            },
            state: {
                from: 'mine-samtaler'
            }
        });
    }
    @track threads;
    @track interpreterThreads;
    @track orderThreads;
    @track ordererUserThreads;

    @track unmappedThreads;
    @track unmappedInterpreterThreads;
    @track unmapperOrderThreads;
    @track unmappedOrdererUserTreads;

    showMythreads = true;
    showInterpreterthreads = false;
    showOrderthreads = false;
    showOrdererUserThreads = false;

    noThreads = false;
    noInterpreterThreads = false;
    noOrderThreads = false;
    noOrdererUserThreads = false;

    ordererThreadsExisting = 0;
    ordererUserThreadsExisting = 0;

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
                    this.unmapperOrderThreads = [];
                    this.unmappedOrdererUserTreads = [];

                    result.data.forEach((element) => {
                        if (element.CRM_Type__c == 'HOT_BRUKER-TOLK') {
                            this.unmappedInterpreterThreads.push(element);
                        }
                        if (element.CRM_Type__c == 'HOT_BRUKER-FORMIDLER') {
                            this.unmappedThreads.push(element);
                        }
                        if (element.CRM_Type__c == 'HOT_BESTILLER-FORMIDLER') {
                            this.unmapperOrderThreads.push(element);
                            this.ordererThreadsExisting++;
                        }
                        if (element.CRM_Type__c == 'HOT_BRUKER-BESTILLER') {
                            this.unmappedOrdererUserTreads.push(element);
                            this.ordererUserThreadsExisting++;
                        }
                    });
                    if (this.ordererUserThreadsExisting > 0) {
                        if (this.tabs.some((tab) => tab.name === 'ordererUserThreads')) {
                        } else {
                            this.tabs.push({
                                name: 'ordererUserThreads',
                                label: 'Bestiller-Bruker',
                                selected: false,
                                hasUnread: false
                            });
                        }
                    }
                    if (this.ordererThreadsExisting > 0) {
                        if (this.tabs.some((tab) => tab.name === 'orderThreads')) {
                        } else {
                            this.tabs.push({
                                name: 'orderThreads',
                                label: 'Annen bestiller',
                                selected: false,
                                hasUnread: false
                            });
                        }
                    }
                    this.threads = this.unmappedThreads.map((x) => ({
                        ...x,
                        read: !String(x.HOT_Thread_read_by__c).includes(contactId) ? false : true,
                        lastMessage: this.formatDateTime(x.CRM_Latest_Message_Datetime__c),
                        appointmentDate: x.HOT_AppointmentStartTime__c,
                        appointmentStart: this.formatDateTime(x.HOT_AppointmentStartTime__c)
                    }));
                    this.interpreterThreads = this.unmappedInterpreterThreads.map((x) => ({
                        ...x,
                        read: !String(x.HOT_Thread_read_by__c).includes(contactId) ? false : true,
                        lastMessage: this.formatDateTime(x.CRM_Latest_Message_Datetime__c),
                        appointmentDate: x.HOT_AppointmentStartTime__c,
                        appointmentStart: this.formatDateTime(x.HOT_AppointmentStartTime__c)
                    }));
                    this.orderThreads = this.unmapperOrderThreads.map((x) => ({
                        ...x,
                        read: !String(x.HOT_Thread_read_by__c).includes(contactId) ? false : true,
                        lastMessage: this.formatDateTime(x.CRM_Latest_Message_Datetime__c),
                        appointmentDate: x.HOT_AppointmentStartTime__c,
                        appointmentStart: this.formatDateTime(x.HOT_AppointmentStartTime__c)
                    }));
                    this.ordererUserThreads = this.unmappedOrdererUserTreads.map((x) => ({
                        ...x,
                        read: !String(x.HOT_Thread_read_by__c).includes(contactId) ? false : true,
                        lastMessage: this.formatDateTime(x.CRM_Latest_Message_Datetime__c),
                        appointmentDate: x.HOT_AppointmentStartTime__c,
                        appointmentStart: this.formatDateTime(x.HOT_AppointmentStartTime__c)
                    }));

                    this.noThreads = this.threads.length === 0;
                    this.noInterpreterThreads = this.interpreterThreads.length === 0;
                    this.noOrderThreads = this.orderThreads.length === 0;
                    this.noOrdererUserThreads = this.ordererUserThreads.length === 0;

                    //sorting, unread first
                    this.threads.sort((a, b) => {
                        if (a.read === b.read) {
                            return a.appointmentDate.localeCompare(b.appointmentDate);
                        }
                        return a.read ? 1 : -1;
                    });
                    this.interpreterThreads.sort((a, b) => {
                        if (a.read === b.read) {
                            return a.appointmentDate.localeCompare(b.appointmentDate);
                        }
                        return a.read ? 1 : -1;
                    });
                    this.orderThreads.sort((a, b) => {
                        if (a.read === b.read) {
                            return a.appointmentDate.localeCompare(b.appointmentDate);
                        }
                        return a.read ? 1 : -1;
                    });
                    this.ordererUserThreads.sort((a, b) => {
                        if (a.read === b.read) {
                            return a.appointmentDate.localeCompare(b.appointmentDate);
                        }
                        return a.read ? 1 : -1;
                    });

                    //List 1 unread messages
                    let foundUnreadDispatcherThreads = false;

                    for (let i = 0; i < this.threads.length; i++) {
                        const thread = this.threads[i];
                        if (thread.read == false) {
                            foundUnreadDispatcherThreads = true;
                            break;
                        }
                    }
                    if (foundUnreadDispatcherThreads) {
                        this.tabs = this.tabs.map((tab) => {
                            if (tab.name === 'mythreads') {
                                return { ...tab, hasUnread: true };
                            }
                            return tab;
                        });
                    } else {
                        this.tabs = this.tabs.map((tab) => {
                            if (tab.name === 'mythreads') {
                                return { ...tab, hasUnread: false };
                            }
                            return tab;
                        });
                    }
                    //List 2 unread messages
                    let foundUnreadInterpreterThreads = false;

                    for (let i = 0; i < this.interpreterThreads.length; i++) {
                        const thread2 = this.interpreterThreads[i];
                        if (thread2.read == false) {
                            foundUnreadInterpreterThreads = true;
                            break;
                        }
                    }
                    if (foundUnreadInterpreterThreads) {
                        this.tabs = this.tabs.map((tab) => {
                            if (tab.name === 'interpreterthreads') {
                                return { ...tab, hasUnread: true };
                            }
                            return tab;
                        });
                    } else {
                        this.tabs = this.tabs.map((tab) => {
                            if (tab.name === 'interpreterthreads') {
                                return { ...tab, hasUnread: false };
                            }
                            return tab;
                        });
                    }
                    //List 3 unread messages

                    let foundUnreadOrdererThreads = false;

                    for (let i = 0; i < this.orderThreads.length; i++) {
                        const thread3 = this.orderThreads[i];
                        if (thread3.read == false) {
                            foundUnreadOrdererThreads = true;
                            break;
                        }
                    }
                    if (foundUnreadOrdererThreads) {
                        this.tabs = this.tabs.map((tab) => {
                            if (tab.name === 'orderThreads') {
                                return { ...tab, hasUnread: true };
                            }
                            return tab;
                        });
                    } else {
                        this.tabs = this.tabs.map((tab) => {
                            if (tab.name === 'orderThreads') {
                                return { ...tab, hasUnread: false };
                            }
                            return tab;
                        });
                    }
                    //List 4 unread messages

                    let foundUnreadOrdererUserThreads = false;

                    for (let i = 0; i < this.ordererUserThreads.length; i++) {
                        const thread5 = this.ordererUserThreads[i];
                        if (thread5.read == false) {
                            foundUnreadOrdererUserThreads = true;
                            break;
                        }
                    }
                    if (foundUnreadOrdererUserThreads) {
                        this.tabs = this.tabs.map((tab) => {
                            if (tab.name === 'ordererUserThreads') {
                                return { ...tab, hasUnread: true };
                            }
                            return tab;
                        });
                    } else {
                        this.tabs = this.tabs.map((tab) => {
                            if (tab.name === 'ordererUserThreads') {
                                return { ...tab, hasUnread: false };
                            }
                            return tab;
                        });
                    }
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
        this.setTable();
        refreshApex(this.wiredThreadsResult);
    }
    renderedCallback() {
        if (sessionStorage.getItem('activeMessageList') != null) {
            this.updateTab({ target: { dataset: { id: sessionStorage.getItem('activeMessageList') } } });
        } else {
            this.updateTab({ target: { dataset: { id: 'mythreads' } } });
        }
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
