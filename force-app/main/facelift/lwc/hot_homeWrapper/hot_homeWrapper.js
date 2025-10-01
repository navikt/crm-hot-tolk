import { LightningElement, wire, track } from 'lwc';
import getUserInformation from '@salesforce/apex/HOT_UserInformationController.getUserInformation';
import getAllMyThreadsForBadge from '@salesforce/apex/HOT_ThreadListController.getAllMyThreadsForBadge';
import getContactId from '@salesforce/apex/HOT_MessageHelper.getUserContactId';

export default class Hot_homeWrapper extends LightningElement {
    personDetails;

    isFreelance = false;

    @wire(getUserInformation, {})
    wireuser({ data }) {
        if (data) {
            this.personDetails = {
                FirstName: data.FirstName,
                ProfileName: data.Profile.Name
            };
            this.isFreelance = data.Profile.Name === 'NAV Samhandler';
        }
    }

    /* FINN ULESTE MELDINGER FOR FRILANS OG BRUKER */

    wiredThreadsResult;
    userContactId;

    freelanceThreads = [];
    myThreads = [];

    @wire(getAllMyThreadsForBadge, { isFreelance: '$isFreelance' })
    wiredThreads(result) {
        this.wiredThreadsResult = result;
        const { data, error } = result;
        if (data) {
            // Setter hver liste i sin egen array
            this.freelanceThreads = data.freelance || [];
            this.myThreads = data.mythreads || [];
            this.tryMapAndSortThreads();
        } else if (error) {
            this.freelanceThreads = [];
            this.myThreads = [];
        }
    }
    @wire(getContactId)
    wiredContactId({ data, error }) {
        if (data) {
            this.userContactId = data;
            this.tryMapAndSortThreads();
        } else if (error) {
            this.error = error;
        }
    }
    tryMapAndSortThreads() {
        if (
            this.userContactId &&
            ((Array.isArray(this.freelanceThreads) && this.freelanceThreads.length > 0) ||
                (Array.isArray(this.myThreads) && this.myThreads.length > 0))
        ) {
            this.mapAndSortThreads();
        }
    }
    unreadMyThreads;
    unreadFreelanceThreads;

    mapAndSortThreads() {
        const uid = this.userContactId;

        // Mapper myThreads og teller uleste
        let unreadMyThreadsCount = 0;
        this.sortedMyThreads = (this.myThreads ?? []).map((t) => {
            const isRead = (t.HOT_Thread_read_by__c || '').includes(uid);
            if (!isRead) unreadMyThreadsCount++;
            return {
                ...t,
                isRead
            };
        });
        this.unreadMyThreads = unreadMyThreadsCount;

        // Mapper freelanceThreads og teller uleste
        let unreadFreelanceThreadsCount = 0;
        this.sortedFreelanceThreads = (this.freelanceThreads ?? []).map((t) => {
            const isRead = (t.HOT_Thread_read_by__c || '').includes(uid);
            if (!isRead) unreadFreelanceThreadsCount++;
            return {
                ...t,
                isRead
            };
        });
        this.unreadFreelanceThreads = unreadFreelanceThreadsCount;

        console.log('Du har ' + this.unreadMyThreads + ' uleste meldinger som bruker.');
        console.log('Du har ' + this.unreadFreelanceThreads + ' uleste meldinger som frilans.');
    }
}
