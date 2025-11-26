import { LightningElement, api } from 'lwc';

export default class hot_announcementWrapper extends LightningElement {
    @api isFreelance = false;
    @api personDetails = {};
    announcements = [
        {
            Type__c: 'Information',
            Title__c: 'Informasjon om tjenesten idag44',
            Description__c: 'Dette er en informasjon til brukerne.\nVennligst les nøye.'
        },
        {
            Type__c: 'Warning',
            Title__c: 'Informasjon om tjenesten idag222',
            Description__c: 'Dette er en informasjon til brukerne.\nVennligst les nøye.',
            CreatedDate: '3 Januar 2025'
        }
    ];
}
