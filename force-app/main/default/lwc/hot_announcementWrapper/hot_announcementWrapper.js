import { LightningElement, api } from 'lwc';

export default class hot_announcementWrapper extends LightningElement {
    @api isFreelance = false;
    @api personDetails = {};
    announcements = [
        {
            Type__c: 'Warning',
            Title__c: 'Tekniske problemer',
            Description__c: 'Tolketjenesten opplever tekniske problemer ved innsending av nye bestillinger.'
        }
    ];
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