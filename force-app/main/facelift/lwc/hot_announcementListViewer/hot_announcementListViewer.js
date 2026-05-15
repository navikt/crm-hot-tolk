import { LightningElement, api } from 'lwc';

import icons from '@salesforce/resourceUrl/ikoner';
import ICON_Newspaper from '@salesforce/resourceUrl/Newspaper';

import getUnreadAnnouncementIds from '@salesforce/apex/HOT_AnnouncementController.getUnreadAnnouncementIds';
import markAnnouncementsAsRead from '@salesforce/apex/HOT_AnnouncementController.markAnnouncementsAsRead';

export default class Hot_announcementListViewer extends LightningElement {
    @api announcements;

    exitCrossIcon = icons + '/Close/Close.svg';
    newspaperIcon = ICON_Newspaper;

    showAnnouncements = false;
    isLoading = false;

    announcementsToShow = 100;
    visibleAnnouncements = [];

    unreadAnnouncementIds = [];

    connectedCallback() {
        this.loadUnreadAnnouncements();
    }

    async loadUnreadAnnouncements() {
        try {
            this.unreadAnnouncementIds = await getUnreadAnnouncementIds();
        } catch (error) {
            console.error('Feil ved henting av uleste announcements', error);
        }
    }

    get unreadCount() {
        return this.unreadAnnouncementIds.length;
    }

    async handleShowAnnouncements() {
        this.updateVisibleAnnouncements();

        const dialog = this.template.querySelector('.modal-announcements');

        dialog.showModal();
        dialog.focus();

        await this.setNewsRead();
    }

    async setNewsRead() {
        if (!this.unreadAnnouncementIds.length) {
            return;
        }

        try {
            await markAnnouncementsAsRead();

            // Fjern badge umiddelbart i UI
            this.unreadAnnouncementIds = [];
        } catch (error) {
            console.error('Feil ved markering av announcements som lest', error);
        }
    }

    handleShowMore() {
        this.announcementsToShow += 10;
        this.updateVisibleAnnouncements();
    }

    updateVisibleAnnouncements() {
        if (!this.announcements) {
            this.visibleAnnouncements = [];
            return;
        }

        this.visibleAnnouncements = this.announcements.slice(0, this.announcementsToShow);
    }

    get hasMore() {
        return this.announcementsToShow < this.announcements.length;
    }

    closeModal() {
        const dialog = this.template.querySelector('.modal-announcements');

        if (dialog) {
            dialog.close();
        }
    }

    get isEmpty() {
        return !this.announcements || this.announcements.length === 0;
    }
}
