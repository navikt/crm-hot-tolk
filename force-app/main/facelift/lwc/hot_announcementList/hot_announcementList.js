import { LightningElement } from 'lwc';

export default class Hot_announcementList extends LightningElement {
    announcementsToShow = 10; // Hvor mange som vises
    visibleAnnouncements = [];

    announcements = [
        {
            Type__c: 'News',
            Title__c: 'Aktivitetsdag på søndag 12 januar 2026',
            CreatedDate: '20 November 2025',
            Description__c:
                'Dette er en informasjon til brukerne.\nVennligst les nøye.\nVi kan dra og ake i akebakken. Håper det blir mye snø og at det er nok snø i bakken til at vi kan renne med kjelke hele dagen lang haha aj det er gøy. Ja det er kjempegøt.',
            CreatedDate: '3 Januar 2025'
        },
        {
            Type__c: 'News',
            Title__c: 'Aktivitetsdag på søndag 12 januar 2026',
            CreatedDate: '20 November 2025',
            Description__c:
                'Dette er en informasjon til brukerne.\nVennligst les nøye.\nVi kan dra og ake i akebakken. Håper det blir mye snø og at det er nok snø i bakken til at vi kan renne med kjelke hele dagen lang haha aj det er gøy. Ja det er kjempegøt.',
            CreatedDate: '3 Januar 2025'
        },
        {
            Type__c: 'News',
            Title__c: 'Aktivitetsdag på søndag 12 januar 2026',
            CreatedDate: '20 November 2025',
            Description__c:
                'Dette er en informasjon til brukerne.\nVennligst les nøye.\nVi kan dra og ake i akebakken. Håper det blir mye snø og at det er nok snø i bakken til at vi kan renne med kjelke hele dagen lang haha aj det er gøy. Ja det er kjempegøt.',
            CreatedDate: '3 Januar 2025'
        },
        {
            Type__c: 'News',
            Title__c: 'Aktivitetsdag på søndag 12 januar 2026',
            CreatedDate: '20 November 2025',
            Description__c:
                'Dette er en informasjon til brukerne.\nVennligst les nøye.\nVi kan dra og ake i akebakken. Håper det blir mye snø og at det er nok snø i bakken til at vi kan renne med kjelke hele dagen lang haha aj det er gøy. Ja det er kjempegøt.',
            CreatedDate: '3 Januar 2025'
        },
        {
            Type__c: 'News',
            Title__c: 'Aktivitetsdag på søndag 12 januar 2026',
            CreatedDate: '20 November 2025',
            Description__c:
                'Dette er en informasjon til brukerne.\nVennligst les nøye.\nVi kan dra og ake i akebakken. Håper det blir mye snø og at det er nok snø i bakken til at vi kan renne med kjelke hele dagen lang haha aj det er gøy. Ja det er kjempegøt.',
            CreatedDate: '3 Januar 2025'
        },
        {
            Type__c: 'News',
            Title__c: 'Aktivitetsdag på søndag 12 januar 2026',
            CreatedDate: '20 November 2025',
            Description__c:
                'Dette er en informasjon til brukerne.\nVennligst les nøye.\nVi kan dra og ake i akebakken. Håper det blir mye snø og at det er nok snø i bakken til at vi kan renne med kjelke hele dagen lang haha aj det er gøy. Ja det er kjempegøt.',
            CreatedDate: '3 Januar 2025'
        },
        {
            Type__c: 'News',
            Title__c: 'Aktivitetsdag på søndag 12 januar 2026',
            CreatedDate: '20 November 2025',
            Description__c:
                'Dette er en informasjon til brukerne.\nVennligst les nøye.\nVi kan dra og ake i akebakken. Håper det blir mye snø og at det er nok snø i bakken til at vi kan renne med kjelke hele dagen lang haha aj det er gøy. Ja det er kjempegøt.',
            CreatedDate: '3 Januar 2025'
        },
        {
            Type__c: 'News',
            Title__c: 'Aktivitetsdag på søndag 12 januar 2026',
            CreatedDate: '20 November 2025',
            Description__c:
                'Dette er en informasjon til brukerne.\nVennligst les nøye.\nVi kan dra og ake i akebakken. Håper det blir mye snø og at det er nok snø i bakken til at vi kan renne med kjelke hele dagen lang haha aj det er gøy. Ja det er kjempegøt.',
            CreatedDate: '3 Januar 2025'
        },
        {
            Type__c: 'News',
            Title__c: 'Aktivitetsdag på søndag 12 januar 2026',
            CreatedDate: '20 November 2025',
            Description__c:
                'Dette er en informasjon til brukerne.\nVennligst les nøye.\nVi kan dra og ake i akebakken. Håper det blir mye snø og at det er nok snø i bakken til at vi kan renne med kjelke hele dagen lang haha aj det er gøy. Ja det er kjempegøt.',
            CreatedDate: '3 Januar 2025'
        },
        {
            Type__c: 'News',
            Title__c: 'Aktivitetsdag på søndag 12 januar 2026',
            CreatedDate: '20 November 2025',
            Description__c:
                'Dette er en informasjon til brukerne.\nVennligst les nøye.\nVi kan dra og ake i akebakken. Håper det blir mye snø og at det er nok snø i bakken til at vi kan renne med kjelke hele dagen lang haha aj det er gøy. Ja det er kjempegøt.',
            CreatedDate: '3 Januar 2025'
        },
        {
            Type__c: 'News',
            Title__c: 'Aktivitetsdag på søndag 12 januar 2026',
            CreatedDate: '20 November 2025',
            Description__c:
                'Dette er en informasjon til brukerne.\nVennligst les nøye.\nVi kan dra og ake i akebakken. Håper det blir mye snø og at det er nok snø i bakken til at vi kan renne med kjelke hele dagen lang haha aj det er gøy. Ja det er kjempegøt.',
            CreatedDate: '3 Januar 2025'
        },
        {
            Type__c: 'News',
            Title__c: 'Aktivitetsdag på søndag 12 januar 2026',
            CreatedDate: '20 November 2025',
            Description__c:
                'Dette er en informasjon til brukerne.\nVennligst les nøye.\nVi kan dra og ake i akebakken. Håper det blir mye snø og at det er nok snø i bakken til at vi kan renne med kjelke hele dagen lang haha aj det er gøy. Ja det er kjempegøt.',
            CreatedDate: '3 Januar 2025'
        },
        {
            Type__c: 'News',
            Title__c: 'Aktivitetsdag på søndag 12 januar 2026',
            CreatedDate: '20 November 2025',
            Description__c:
                'Dette er en informasjon til brukerne.\nVennligst les nøye.\nVi kan dra og ake i akebakken. Håper det blir mye snø og at det er nok snø i bakken til at vi kan renne med kjelke hele dagen lang haha aj det er gøy. Ja det er kjempegøt.',
            CreatedDate: '3 Januar 2025'
        },
        {
            Type__c: 'News',
            Title__c: 'Aktivitetsdag på søndag 12 januar 2026',
            CreatedDate: '20 November 2025',
            Description__c:
                'Dette er en informasjon til brukerne.\nVennligst les nøye.\nVi kan dra og ake i akebakken. Håper det blir mye snø og at det er nok snø i bakken til at vi kan renne med kjelke hele dagen lang haha aj det er gøy. Ja det er kjempegøt.',
            CreatedDate: '3 Januar 2025'
        },
        {
            Type__c: 'News',
            Title__c: 'Aktivitetsdag på søndag 12 januar 2026',
            CreatedDate: '20 November 2025',
            Description__c:
                'Dette er en informasjon til brukerne.\nVennligst les nøye.\nVi kan dra og ake i akebakken. Håper det blir mye snø og at det er nok snø i bakken til at vi kan renne med kjelke hele dagen lang haha aj det er gøy. Ja det er kjempegøt.',
            CreatedDate: '3 Januar 2025'
        }
    ];
    connectedCallback() {
        this.updateVisibleAnnouncements();
    }

    updateVisibleAnnouncements() {
        this.visibleAnnouncements = this.announcements.slice(0, this.announcementsToShow);
    }

    handleShowMore() {
        const previousCount = this.announcementsToShow;
        this.announcementsToShow += 10;

        this.updateVisibleAnnouncements();

        requestAnimationFrame(() => {
            const firstNew = this.template.querySelector(`[data-index="${previousCount}"]`);
            if (firstNew) {
                firstNew.focus();
            }
        });
    }

    get hasMore() {
        return this.announcementsToShow < this.announcements.length;
    }
}