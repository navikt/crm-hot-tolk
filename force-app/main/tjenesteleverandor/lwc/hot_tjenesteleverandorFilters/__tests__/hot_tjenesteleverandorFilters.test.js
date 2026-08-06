import { createDefaultFilters, filterRecords, restoreFilters } from 'c/hot_tjenesteleverandorFilters';

const RECORDS = [
    {
        Id: '08p000000000001AAA',
        EarliestStartTime: '2099-08-01T08:00:00.000Z',
        DueDate: '2099-08-01T09:00:00.000Z',
        HOT_ServiceAppointmentNumber__c: 'SA-0001',
        HOT_FreelanceSubject__c: 'Legetime',
        HOT_WorkTypeName__c: 'TS - Tegnspråk',
        HOT_AssignmentType__c: 'Helsetjenester',
        HOT_ServiceTerritoryDeveloperName__c: 'Oslo',
        HOT_ServiceTerritoryName__c: 'Oslo'
    },
    {
        Id: '08p000000000002AAA',
        EarliestStartTime: '2099-08-03T08:00:00.000Z',
        DueDate: '2099-08-03T09:00:00.000Z',
        HOT_ServiceAppointmentNumber__c: 'SA-0002',
        HOT_FreelanceSubject__c: 'Foreldremøte',
        HOT_WorkTypeName__c: 'SK - Skrivetolking',
        HOT_AssignmentType__c: 'Utdanning',
        HOT_ServiceTerritoryDeveloperName__c: 'Ost_Viken',
        HOT_ServiceTerritoryName__c: 'Øst-Viken'
    }
];

describe('c-hot-tjenesteleverandor-filters', () => {
    beforeEach(() => {
        sessionStorage.clear();
    });

    it('filters appointments by region using the established developer names', () => {
        const filters = createDefaultFilters();
        const regionFilter = filters.find((filter) => filter.name === 'HOT_ServiceTerritoryDeveloperName__c');
        regionFilter.value.find((region) => region.name === 'Ost_Viken').value = true;

        expect(filterRecords(RECORDS, filters).map((record) => record.Id)).toEqual([RECORDS[1].Id]);
    });

    it('combines date, checkbox and case-insensitive search filters', () => {
        const filters = createDefaultFilters();
        filters.find((filter) => filter.isDateInterval).value[0].value = '2099-08-02';
        filters
            .find((filter) => filter.name === 'HOT_WorkTypeName__c')
            .value.find((workType) => workType.name === 'SK - Skrivetolking').value = true;
        filters.find((filter) => filter.isSearch).searchTerm = 'FORELDRE';

        expect(filterRecords(RECORDS, filters)).toEqual([RECORDS[1]]);
    });

    it('returns fresh defaults when saved filters are invalid', () => {
        sessionStorage.setItem('filters', 'invalid json');

        const filters = restoreFilters('filters');

        expect(filters).toHaveLength(5);
        expect(sessionStorage.getItem('filters')).toBeNull();
    });
});
