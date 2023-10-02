import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getMyThreads from '@salesforce/apex/HOT_ThreadListController.getMyThreadsFreelance';
import getContactId from '@salesforce/apex/HOT_MessageHelper.getUserContactId';
import { refreshApex } from '@salesforce/apex';

export default class Hot_frilanstolkThreadList extends NavigationMixin(LightningElement) {
    @track userContactId;
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
            label: 'Mine samtaler som frilanstolk',
            href: 'mine-samtaler-frilanstolk'
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
            label: 'Oppdragsstart',
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
            label: 'Oppdragsstart',
            name: 'appointmentStart',
            type: 'text',
            bold: true
        }
    ];
    @track tabs = [
        { name: 'mythreads', label: 'Med formidler', selected: true, hasUnread: false },
        { name: 'interpreterthreads', label: 'Med bruker', selected: false, hasUnread: false },
        { name: 'interpreterInterpreterThreads', label: 'Med andre tolker', selected: false, hasUnread: false },
        { name: 'wageClaimThreads', label: 'Med ressurskontor', selected: false, hasUnread: false }
    ];

    @track tabMap = {
        mythreads: true,
        interpreterthreads: false,
        interpreterInterpreterThreads: false,
        wageClaimThreads: false
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
                    this.showWageClaimthreads = false;
                    this.showOrdererUserThreads = false;
                    this.showInterpreterInterpreterThreads = false;
                }
                if (this.activeTab == 'interpreterthreads') {
                    this.showMythreads = false;
                    this.showInterpreterthreads = true;
                    this.showOrderthreads = false;
                    this.showWageClaimthreads = false;
                    this.showOrdererUserThreads = false;
                    this.showInterpreterInterpreterThreads = false;
                }
                if (this.activeTab == 'wageClaimThreads') {
                    this.showMythreads = false;
                    this.showInterpreterthreads = false;
                    this.showOrderthreads = false;
                    this.showWageClaimthreads = true;
                    this.showOrdererUserThreads = false;
                    this.showInterpreterInterpreterThreads = false;
                }
                if (this.activeTab == 'interpreterInterpreterThreads') {
                    this.showMythreads = false;
                    this.showInterpreterthreads = false;
                    this.showOrderthreads = false;
                    this.showWageClaimthreads = false;
                    this.showOrdererUserThreads = false;
                    this.showInterpreterInterpreterThreads = true;
                }
            }
        }
        sessionStorage.setItem('activeMessageList', this.activeTab);
        this.updateTabStyle();
    }
    openThread(event) {
        const baseUrl = '/samtale-frilans';
        const attributes = `recordId=${event.detail.Id}&from=mine-samtaler-frilanstolk`;
        const url = `${baseUrl}?${attributes}`;

        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: url
            }
        });
    }
    @track threads;
    @track interpreterThreads;
    @track wageClaimThreads;
    @track interpreterInterpreterThreads;

    @track unmappedThreads;
    @track unmappedInterpreterThreads;
    @track unmappedWageClaimThreads;
    @track unmappedInterpreterInterpreterThreads;

    showMythreads = true;
    showInterpreterthreads = false;
    showWageClaimthreads = false;
    showInterpreterInterpreterThreads = false;

    noThreads = false;
    noInterpreterThreads = false;
    noWageClaimThreads = false;
    noInterpreterInterpreterThreads = false;

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
                    this.unmappedWageClaimThreads = [];
                    this.unmappedInterpreterInterpreterThreads = [];

                    result.data.forEach((element) => {
                        if (element.CRM_Type__c == 'HOT_BRUKER-TOLK') {
                            this.unmappedInterpreterThreads.push(element);
                        }
                        if (element.CRM_Type__c == 'HOT_TOLK-FORMIDLER') {
                            this.unmappedThreads.push(element);
                        }
                        if (element.CRM_Type__c == 'HOT_TOLK-RESSURSKONTOR') {
                            this.unmappedWageClaimThreads.push(element);
                            this.wageClaimThreadsExisting++;
                        }
                        if (element.CRM_Type__c == 'HOT_TOLK-TOLK') {
                            this.unmappedInterpreterInterpreterThreads.push(element);
                            this.interpreterInterpreterThreadsExisting++;
                        }
                    });
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
                    this.wageClaimThreads = this.unmappedWageClaimThreads.map((x) => ({
                        ...x,
                        read: !String(x.HOT_Thread_read_by__c).includes(contactId) ? false : true,
                        lastMessage: this.formatDateTime(x.CRM_Latest_Message_Datetime__c),
                        appointmentDate: x.HOT_AppointmentStartTime__c,
                        appointmentStart: this.formatDateTime(x.HOT_AppointmentStartTime__c)
                    }));
                    this.interpreterInterpreterThreads = this.unmappedInterpreterInterpreterThreads.map((x) => ({
                        ...x,
                        read: !String(x.HOT_Thread_read_by__c).includes(contactId) ? false : true,
                        lastMessage: this.formatDateTime(x.CRM_Latest_Message_Datetime__c),
                        appointmentDate: x.HOT_AppointmentStartTime__c,
                        appointmentStart: this.formatDateTime(x.HOT_AppointmentStartTime__c)
                    }));

                    this.noThreads = this.threads.length === 0;
                    this.noInterpreterThreads = this.interpreterThreads.length === 0;
                    this.noWageClaimThreads = this.wageClaimThreads.length === 0;
                    this.noInterpreterInterpreterThreads = this.interpreterInterpreterThreads.length === 0;

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
                    this.wageClaimThreads.sort((a, b) => {
                        if (a.read === b.read) {
                            return a.appointmentDate.localeCompare(b.appointmentDate);
                        }
                        return a.read ? 1 : -1;
                    });
                    this.interpreterInterpreterThreads.sort((a, b) => {
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

                    let foundUnreadwageClaimThreads = false;

                    for (let i = 0; i < this.wageClaimThreads.length; i++) {
                        const thread4 = this.wageClaimThreads[i];
                        if (thread4.read == false) {
                            foundUnreadwageClaimThreads = true;
                            break;
                        }
                    }
                    if (foundUnreadwageClaimThreads) {
                        this.tabs = this.tabs.map((tab) => {
                            if (tab.name === 'wageClaimThreads') {
                                return { ...tab, hasUnread: true };
                            }
                            return tab;
                        });
                    } else {
                        this.tabs = this.tabs.map((tab) => {
                            if (tab.name === 'wageClaimThreads') {
                                return { ...tab, hasUnread: false };
                            }
                            return tab;
                        });
                    }
                    //List 4 unread messages

                    let foundUnreadInterpreterInterpreterThreads = false;

                    for (let i = 0; i < this.interpreterInterpreterThreads.length; i++) {
                        const thread6 = this.interpreterInterpreterThreads[i];
                        if (thread6.read == false) {
                            foundUnreadInterpreterInterpreterThreads = true;
                            break;
                        }
                    }
                    if (foundUnreadInterpreterInterpreterThreads) {
                        this.tabs = this.tabs.map((tab) => {
                            if (tab.name === 'interpreterInterpreterThreads') {
                                return { ...tab, hasUnread: true };
                            }
                            return tab;
                        });
                    } else {
                        this.tabs = this.tabs.map((tab) => {
                            if (tab.name === 'interpreterInterpreterThreads') {
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
