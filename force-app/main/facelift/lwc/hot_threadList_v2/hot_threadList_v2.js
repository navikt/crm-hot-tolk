import { LightningElement, api, wire } from 'lwc';
import getMyThreads from '@salesforce/apex/HOT_ThreadListController.getAllMyThreads';
import getContactId from '@salesforce/apex/HOT_MessageHelper.getUserContactId';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';

export default class Hot_threadList_v2 extends NavigationMixin(LightningElement) {
    @api isFreelanceView;

    data;
    error;
    threads;
    noTreads = false;
    hasThreads = false;
    userContactId;
    filterValue;
    searchValue;

    sortedThreads = [];
    wiredThreadsResult;
    shouldRefreshAfterWire = false;
    unreadThreadsCount;

    get headerText() {
        if (this.isFreelanceView) {
            return 'Mine samtaler som frilans';
        } else {
            return 'Mine samtaler';
        }
    }
    connectedCallback() {
        this.shouldRefreshAfterWire = true;
    }

    @wire(getMyThreads, { isFreelance: '$isFreelanceView' })
    wiredThreads(value) {
        this.wiredThreadsResult = value;
        const { data, error } = value;

        if (data) {
            this.threads = data;
            this.error = undefined;
            this.tryMapAndSortThreads();
        } else if (error) {
            this.error = error;
            this.threads = undefined;
        }
        console.log('wire error:', error);
        if (this.shouldRefreshAfterWire) {
            this.shouldRefreshAfterWire = false;
            refreshApex(this.wiredThreadsResult)
                .then(() => this.tryMapAndSortThreads())
                .catch((e) => console.error('refreshApex failed', e));
        }
    }
    @wire(getContactId, {})
    wiredContactId({ data, error }) {
        if (data) {
            this.userContactId = data;
            this.tryMapAndSortThreads();
        } else if (error) {
            this.error = error;
        }
        console.log('contactid feil', error);
    }
    handleFilterButtonClick(event) {
        this.filterValue = event.detail;
        this.tryMapAndSortThreads();
    }
    handleSearchChange(event) {
        this.searchValue = event.detail;
        this.tryMapAndSortThreads();
    }

    tryMapAndSortThreads() {
        if (this.userContactId && Array.isArray(this.threads)) {
            this.mapAndSortThreads();
        }
    }
    mapAndSortThreads() {
        const uid = this.userContactId;
        const fv = this.filterValue;
        const sv = (this.searchValue ?? '').trim().toLowerCase(); // søkestreng

        const hasFilter = !!fv && fv !== 'all'; //Sjekke om filterverdi er satt og ikke er all
        const hasSearch = sv.length > 0; //sjekker om det er søkestreng verdi

        this.sortedThreads = (this.threads ?? [])
            .filter((t) => {
                // trådtype‑filter
                if (hasFilter && t.CRM_Thread_Type__c !== fv) return false;

                //  søkestreng‑filter
                if (hasSearch) {
                    const subject = (t.HOT_Subject__c || '').toLowerCase();
                    if (!subject.includes(sv)) return false;
                }

                return true;
            })
            .map((t) => {
                const isRead = (t.HOT_Thread_read_by__c || '').includes(uid);
                return {
                    ...t,
                    isRead,
                    statusText: isRead ? 'Lest' : 'Ulest',
                    statusClass: isRead ? 'tagBox readThread' : 'tagBox unreadThread',
                    latestMessageSent: new Date(t.CRM_Latest_Message_Datetime__c || 0).getTime(),
                    lastMessageSentFormatted: this.formatDateTime(t.CRM_Latest_Message_Datetime__c),
                    appointmentStartFormatted: this.formatDateTime(t.HOT_AppointmentStartTime__c),
                    threadTypeName: this.getThreadTypeName(t.CRM_Thread_Type__c)
                };
            })
            .sort((a, b) => {
                if (a.isRead !== b.isRead) return a.isRead ? 1 : -1; // ulest først
                return b.latestMessageSent - a.latestMessageSent; // nyeste først
            });

        this.unreadThreadsCount = this.sortedThreads.filter((t) => !t.isRead).length;

        if (this.sortedThreads.length == 0) {
            this.noTreads = true;
            this.hasThreads = false;
        } else {
            this.noTreads = false;
            this.hasThreads = true;
        }
    }
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
    getThreadTypeName(threadTypeValue) {
        if (threadTypeValue === 'HOT_BRUKER-FORMIDLER') {
            return 'Med formidler';
        }
        if (threadTypeValue === 'HOT_BESTILLER-FORMIDLER') {
            return 'Med formidler';
        }
        if (threadTypeValue === 'HOT_BRUKER-TOLK') {
            if (this.isFreelanceView == true) {
                return 'Med bruker';
            } else {
                return 'Med tolk';
            }
        }
        if (threadTypeValue === 'HOT_BRUKER-BESTILLER') {
            return 'Samtale mellom bruker og bestiller)';
        }
        if (threadTypeValue === 'HOT_TOLK-FORMIDLER') {
            return 'Med formidler';
        }
        if (threadTypeValue === 'HOT_TOLK-RESSURSKONTOR') {
            return 'Med ressurskontor';
        }
        if (threadTypeValue === 'HOT_TOLK-TOLK') {
            return 'Med bare medtolker';
        } else {
            return '';
        }
    }
    goToThread(event) {
        // Vi skal lage en record page for alle typer tråder men foreløpig nå må den gå til hver sin.
        if (this.isFreelanceView) {
            const baseUrl = '/samtale-frilans';
            const attributes = `recordId=${event.detail}&from=mine-samtaler-frilanstolk`;
            const url = `${baseUrl}?${attributes}`;

            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: url
                }
            });
        } else {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: event.detail,
                    objectApiName: 'Thread__c',
                    actionName: 'view'
                },
                state: {
                    from: 'mine-samtaler',
                    recordId: event.detail,
                    level: 'WO'
                }
            });
        }
    }
}
