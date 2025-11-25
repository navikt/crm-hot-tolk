import { LightningElement, api } from 'lwc';

export default class hot_announcementWrapper extends LightningElement {
    @api isFreelance = false;
    @api personDetails = {};
    announcements = [
        {
            Type__c: 'Information',
            Title__c: 'Informasjon om tjenesten idag',
            Description__c: 'Dette er en informasjon til brukerne.\nVennligst les nøye.'
        }
    ];
}
