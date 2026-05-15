import { LightningElement, api } from 'lwc';

import icons from '@salesforce/resourceUrl/ikoner';
import ICON_Newspaper from '@salesforce/resourceUrl/Newspaper';
import markAnnouncementsAsRead from '@salesforce/apex/HOT_AnnouncementController.markAnnouncementsAsRead';

export default class Hot_announcementListViewer extends LightningElement {
    @api announcements;
    @api unreadAnnouncementIds = [];

    exitCrossIcon = icons + '/Close/Close.svg';
    newspaperIcon = ICON_Newspaper;

    showAnnouncements = false;
    isLoading = false;

    announcementsToShow = 100;
    visibleAnnouncements = [];

    get unreadCount() {
        return (this.unreadAnnouncementIds || []).length;
    }

    async handleShowAnnouncements() {
        this.updateVisibleAnnouncements();

        const dialog = this.template.querySelector('.modal-announcements');

        if (dialog) {
            dialog.showModal();
            dialog.focus();
        }

        await this.setNewsRead();
    }

    async setNewsRead() {
        if (!this.unreadCount) {
            return;
        }

        try {
            await markAnnouncementsAsRead();
            this.unreadAnnouncementIds = [];
        } catch (error) {
            console.error('Feil ved markering av nyhet som lest', error);
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
        return this.announcementsToShow < (this.announcements || []).length;
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

    get announcementButtonLabel() {
        if (this.unreadCount === 1) {
            return 'Nyheter fra Tolketjenesten. Du har 1 ulest nyhet';
        }

        if (this.unreadCount > 1) {
            return `Nyheter fra Tolketjenesten. Du har ${this.unreadCount} uleste nyheter`;
        }

        return 'Nyheter fra Tolketjenesten. Du har ingen uleste nyheter';
    }
}
