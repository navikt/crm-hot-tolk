import { LightningElement } from 'lwc';
import getMyThreads from '@salesforce/apex/HOT_MobileThreadListcontroller.getThreads';
import { NavigationMixin } from 'lightning/navigation';
import userId from '@salesforce/user/Id';

export default class hot_mobileThreadList extends NavigationMixin(LightningElement) {
    data;
    error;
    threads;
    noTreads = false;
    hasThreads = false;
    filterValue;
    searchValue;

    sortedThreads = [];
    wiredThreadsResult;
    unreadThreadsCount;

    connectedCallback() {
        this.loadData();
    }

    loadData() {
        getMyThreads()
            .then((threadData) => {
                this.threads = threadData;
                this.error = undefined;
                this.tryMapAndSortThreads();
            })
            .catch((error) => {
                this.error = error;
                this.threads = [];
                console.error('Feil i henting av data:', error);
            });
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
        if (Array.isArray(this.threads)) {
            this.mapAndSortThreads();
        }
    }
    mapAndSortThreads() {
        const uid = userId;
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
            return 'Med bruker';
        }
        if (threadTypeValue === 'HOT_BRUKER-BESTILLER') {
            return 'Samtale mellom bruker og bestiller';
        }
        if (threadTypeValue === 'HOT_TOLK-FORMIDLER') {
            return 'Med formidler';
        }
        if (threadTypeValue === 'HOT_TOLK-RESSURSKONTOR') {
            return 'Med ressurskontor';
        }
        if (threadTypeValue === 'HOT_TOLK-TOLK') {
            return 'Med medtolk';
        } else {
            return '';
        }
    }
    goToThread(event) {
        // Vi skal lage en record page for alle typer tråder men foreløpig nå må den gå til hver sin.

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: event.detail,
                objectApiName: 'Thread__c',
                actionName: 'view'
            }
        });
    }
}
