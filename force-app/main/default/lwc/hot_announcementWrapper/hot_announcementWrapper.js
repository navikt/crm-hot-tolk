import { LightningElement, api } from 'lwc';

export default class hot_announcementWrapper extends LightningElement {
    @api announcements;
    // announcements = [
    //     {
    //         Type__c: 'Information',
    //         Title__c: 'Ingen tolker tilgjengelig fredag',
    //         Description__c: 'Dette er en informasjon til brukerne.\nVennligst les nøye.'
    //     },
    //     {
    //         Type__c: 'Warning',
    //         Title__c: 'Feil under utsendelse av SMS',
    //         Description__c: 'En feil gjør at det ikke vil bli utsendt sms.\nVennligst les nøye.'
    //     },
    //     {
    //         Type__c: 'Information',
    //         Title__c: 'Ingen tolker tilgjengelig mandag',
    //         Description__c: 'Dette er en informasjon til brukerne.\nVennligst les nøye.'
    //     }
    // ];
    get groupedAnnouncements() {
        const groups = {};

        this.announcements.forEach((a) => {
            if (!groups[a.Type__c]) {
                groups[a.Type__c] = [];
            }
            groups[a.Type__c].push(a);
        });

        return Object.keys(groups).map((type) => ({
            type,
            items: groups[type]
        }));
    }
}
