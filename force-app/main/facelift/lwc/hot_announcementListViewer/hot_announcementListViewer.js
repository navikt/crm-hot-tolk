import { LightningElement, api } from 'lwc';
import icons from '@salesforce/resourceUrl/ikoner';
import ICON_Newspaper from '@salesforce/resourceUrl/Newspaper';

export default class Hot_announcementListViewer extends LightningElement {
    @api announcements;
    exitCrossIcon = icons + '/Close/Close.svg';
    newspaperIcon = ICON_Newspaper;
    showAnnouncements = false;
    isLoading = false;

    announcementsToShow = 10;
    visibleAnnouncements = [];

    handleShowAnnouncements() {
        this.updateVisibleAnnouncements();
        // this.isLoading = true;

        const dialog = this.template.querySelector('.modal-announcements');
        dialog.showModal();
        dialog.focus();

        // loading kun til test
        // setTimeout(() => {
        //     this.visibleAnnouncements = this.announcements.slice(0, this.announcementsToShow);
        //     this.isLoading = false;
        // }, 200);
    }

    handleShowMore() {
        this.announcementsToShow += 10;
        this.updateVisibleAnnouncements();
    }

    updateVisibleAnnouncements() {
        this.visibleAnnouncements = this.announcements.slice(0, this.announcementsToShow);
    }

    get hasMore() {
        return this.announcementsToShow < this.announcements.length;
    }

    closeModal() {
        const dialog = this.template.querySelector('.modal-announcements');
        dialog.close();
    }
    get isEmpty() {
        return !this.announcements || this.announcements.length === 0;
    }
}
