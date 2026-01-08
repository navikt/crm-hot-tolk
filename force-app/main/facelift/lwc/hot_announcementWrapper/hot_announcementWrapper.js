import { LightningElement, api } from 'lwc';

export default class hot_announcementWrapper extends LightningElement {
    get hasAnnouncements() {
        return this.groupedAnnouncements && this.groupedAnnouncements.length > 0;
    }

    @api announcements;
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
