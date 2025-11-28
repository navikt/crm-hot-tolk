import { LightningElement, api } from 'lwc';
import icons from '@salesforce/resourceUrl/ikoner';
import ICON_Newspaper from '@salesforce/resourceUrl/Newspaper';

export default class Hot_announcementPopup extends LightningElement {
    @api announcements;
    exitCrossIcon = icons + '/Close/Close.svg';
    newspaperIcon = ICON_Newspaper;
    showAnnouncements = false;
    isLoading = false;

    announcementsToShow = 10;
    visibleAnnouncements = [];
    // announcements = [
    //     {
    //         Type__c: 'News',
    //         Title__c: 'Aktivitetsdag på søndag 12 januar 2026',
    //         CreatedDate: '20 November 2025',
    //         Description__c:
    //             'Dette er en informasjon til brukerne.\nVennligst les nøye.\nVi kan dra og ake i akebakken. Håper det blir mye snø og at det er nok snø i bakken til at vi kan renne med kjelke hele dagen lang haha aj det er gøy. Ja det er kjempegøt.',
    //         CreatedDate: '3 Januar 2025'
    //     },
    //     {
    //         Type__c: 'News',
    //         Title__c: 'Aktivitetsdag på søndag 12 januar 2026',
    //         CreatedDate: '20 November 2025',
    //         Description__c:
    //             'Dette er en informasjon til brukerne.\nVennligst les nøye.\nVi kan dra og ake i akebakken. Håper det blir mye snø og at det er nok snø i bakken til at vi kan renne med kjelke hele dagen lang haha aj det er gøy. Ja det er kjempegøt.',
    //         CreatedDate: '3 Januar 2025'
    //     }
    // ];

    connectedCallback() {
        this.updateVisibleAnnouncements();
    }

    handleShowAnnouncements() {
        this.isLoading = true;

        const dialog = this.template.querySelector('.modal-announcements');
        dialog.showModal();
        dialog.focus();

        // loading kun til test
        setTimeout(() => {
            this.visibleAnnouncements = this.announcements.slice(0, this.announcementsToShow);
            this.isLoading = false;
        }, 200);
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
}
