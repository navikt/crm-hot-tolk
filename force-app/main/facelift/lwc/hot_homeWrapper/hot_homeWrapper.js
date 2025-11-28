import { LightningElement } from 'lwc';
import getUserInformation from '@salesforce/apex/HOT_UserInformationController.getUserInformation';
import getAllMyThreadsForBadge from '@salesforce/apex/HOT_ThreadListController.getAllMyThreadsForBadge';
import getContactId from '@salesforce/apex/HOT_MessageHelper.getUserContactId';
import getAnnouncements from '@salesforce/apex/HOT_AnnouncementController.getAnnouncements';

export default class Hot_homeWrapper extends LightningElement {
    personDetails;
    isFreelance = false;
    userContactId;

    myThreads = [];
    freelanceThreads = [];
    announcements = [];
    infoWarningAnnouncements = [];
    newsAnnouncements = [];

    unreadMyThreads = 0;
    unreadFreelanceThreads = 0;

    error;

    connectedCallback() {
        this.loadData();
    }
    loadData() {
        getUserInformation()
            .then((userInfo) => {
                this.personDetails = {
                    FirstName: userInfo.FirstName,
                    ProfileName: userInfo.Profile.Name
                };
                this.isFreelance = userInfo.Profile.Name === 'NAV Samhandler';
                return getContactId();
            })
            .then((contactId) => {
                this.userContactId = contactId;
                return getAllMyThreadsForBadge({ isFreelance: this.isFreelance });
            })
            .then((threadsData) => {
                this.freelanceThreads = threadsData.freelance || [];
                this.myThreads = threadsData.mythreads || [];
                this.mapAndSortThreads();
            })
            .catch((error) => {
                this.error = error;
                console.error('Feil:', error);
                this.myThreads = [];
                this.freelanceThreads = [];
            });
        getAnnouncements()
            .then((announcements) => {
                // Array for Information + Warning
                this.infoWarningAnnouncements = announcements.filter(
                    (ann) => ann.Type__c === 'Information' || ann.Type__c === 'Warning'
                );

                // Array for News
                this.newsAnnouncements = announcements.filter((ann) => ann.Type__c === 'News');
            })
            .catch((error) => {
                console.error('Error fetching announcements:', error);
            });
    }

    mapAndSortThreads() {
        if (!this.userContactId) return;

        const uid = this.userContactId;

        let unreadMyThreadsCount = 0;
        this.myThreads = (this.myThreads ?? []).map((t) => {
            const isRead = (t.HOT_Thread_read_by__c || '').includes(uid);
            if (!isRead) unreadMyThreadsCount++;
            return { ...t, isRead };
        });
        this.unreadMyThreads = unreadMyThreadsCount;

        let unreadFreelanceThreadsCount = 0;
        this.freelanceThreads = (this.freelanceThreads ?? []).map((t) => {
            const isRead = (t.HOT_Thread_read_by__c || '').includes(uid);
            if (!isRead) unreadFreelanceThreadsCount++;
            return { ...t, isRead };
        });
        this.unreadFreelanceThreads = unreadFreelanceThreadsCount;

        console.log('Du har ' + this.unreadMyThreads + ' uleste meldinger som bruker.');
        console.log('Du har ' + this.unreadFreelanceThreads + ' uleste meldinger som frilans.');
    }
}
