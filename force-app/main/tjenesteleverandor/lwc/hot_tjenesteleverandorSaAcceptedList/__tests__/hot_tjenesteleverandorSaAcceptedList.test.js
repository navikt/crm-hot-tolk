import { createElement } from 'lwc';
import HotTjenesteleverandorSaAcceptedList from 'c/hot_tjenesteleverandorSaAcceptedList';
import getAcceptedServiceAppointments from '@salesforce/apex/HOT_TjenesteleverandorListController.getAcceptedServiceAppointments';
import { Navigate } from 'lightning/navigation';
import { createDefaultFilters } from 'c/hot_tjenesteleverandorFilters';

jest.mock(
    '@salesforce/apex/HOT_TjenesteleverandorListController.getAcceptedServiceAppointments',
    () => {
        const { createApexTestWireAdapter } = require('@salesforce/sfdx-lwc-jest');
        return { default: createApexTestWireAdapter(jest.fn()) };
    },
    { virtual: true }
);

const APPOINTMENTS = [
    {
        Id: '08p000000000001AAA',
        EarliestStartTime: '2099-08-01T08:00:00.000Z',
        DueDate: '2099-08-01T09:00:00.000Z',
        Status: 'Released to Freelance',
        AppointmentNumber: 'SA-0001',
        HOT_FreelanceSubject__c: 'Tema 1',
        HOT_WorkTypeName__c: 'TS - Tegnspråk',
        HOT_AssignmentType__c: 'Helsetjenester',
        HOT_ServiceTerritoryDeveloperName__c: 'Oslo',
        HOT_ServiceTerritoryName__c: 'Oslo',
        HOT_IsOtherEconomicProvicer__c: true
    },
    {
        Id: '08p000000000002AAA',
        EarliestStartTime: '2099-08-02T08:00:00.000Z',
        DueDate: '2099-08-02T09:00:00.000Z',
        Status: 'Released to Freelance',
        AppointmentNumber: 'SA-0002',
        HOT_FreelanceSubject__c: 'Tema 2',
        HOT_WorkTypeName__c: 'SK - Skrivetolking',
        HOT_AssignmentType__c: 'Utdanning',
        HOT_ServiceTerritoryDeveloperName__c: 'Ost_Viken',
        HOT_ServiceTerritoryName__c: 'Øst-Viken',
        HOT_IsOtherEconomicProvicer__c: false
    }
];

const APPOINTMENT = APPOINTMENTS[0];

const flushPromises = () => new Promise((resolve) => setTimeout(resolve, 0));

function createComponent() {
    const element = createElement('c-hot-tjenesteleverandor-sa-accepted-list', {
        is: HotTjenesteleverandorSaAcceptedList
    });
    document.body.appendChild(element);
    return element;
}

describe('c-hot-tjenesteleverandor-sa-accepted-list', () => {
    beforeEach(() => {
        sessionStorage.clear();
        HTMLDialogElement.prototype.showModal = jest.fn();
    });

    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        Navigate.mockClear();
    });

    it('renders accepted appointments from the wire', async () => {
        const element = createComponent();
        getAcceptedServiceAppointments.emit(APPOINTMENTS);
        await flushPromises();

        const table = element.shadowRoot.querySelector('c-hot_freelance-common-table');
        expect(table.records).toHaveLength(2);
        expect(table.records[0].isOtherProvider).toBe('Ja');
        expect(element.shadowRoot.querySelector('c-hot_loader')).toBeNull();
    });

    it('filters accepted appointments by region', async () => {
        const element = createComponent();
        getAcceptedServiceAppointments.emit(APPOINTMENTS);
        await flushPromises();
        const filters = createDefaultFilters();
        const regionFilter = filters.find((filter) => filter.name === 'HOT_ServiceTerritoryDeveloperName__c');
        regionFilter.value.find((region) => region.name === 'Ost_Viken').value = true;

        const filteredRecordsLength = element.applyFilter({
            detail: { filterArray: filters, setRecords: true }
        });
        await flushPromises();

        const table = element.shadowRoot.querySelector('c-hot_freelance-common-table');
        expect(filteredRecordsLength).toBe(1);
        expect(table.records.map((record) => record.Id)).toEqual([APPOINTMENTS[1].Id]);
    });

    it('opens the existing modal and routes Vis mer info to the separate Experience page', async () => {
        const element = createComponent();
        getAcceptedServiceAppointments.emit(APPOINTMENTS);
        await flushPromises();

        element.shadowRoot
            .querySelector('c-hot_freelance-common-table')
            .dispatchEvent(new CustomEvent('rowclick', { detail: APPOINTMENT }));
        await flushPromises();

        expect(HTMLDialogElement.prototype.showModal).toHaveBeenCalledTimes(1);
        expect(element.shadowRoot.querySelector('.modal-body').textContent).toContain('SA-0001');

        element.shadowRoot.querySelector('.modal-footer c-button').dispatchEvent(new CustomEvent('buttonclick'));

        expect(Navigate).toHaveBeenCalledWith(
            {
                type: 'comm__namedPage',
                attributes: { name: 'Oppdragsdetaljer__c' },
                state: { c__recordId: APPOINTMENT.Id }
            },
            undefined
        );
    });
});
