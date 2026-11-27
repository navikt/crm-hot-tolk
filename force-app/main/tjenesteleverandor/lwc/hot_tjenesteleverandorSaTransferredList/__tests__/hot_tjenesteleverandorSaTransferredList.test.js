import { createElement } from 'lwc';
import HotTjenesteleverandorSaTransferredList from 'c/hot_tjenesteleverandorSaTransferredList';
import getTransferredServiceAppointments from '@salesforce/apex/HOT_TjenesteleverandorListController.getTransferredServiceAppointments';
import acceptServiceAppointments from '@salesforce/apex/HOT_TjenesteleverandorAcceptanceService.acceptServiceAppointments';
import { refreshApex } from '@salesforce/apex';
import { Navigate } from 'lightning/navigation';
import { createDefaultFilters } from 'c/hot_tjenesteleverandorFilters';

jest.mock('@salesforce/customPermission/HOT_AcceptTjenesteleverandorOppdrag', () => ({ default: true }), {
    virtual: true
});
jest.mock('@salesforce/customPermission/HOT_DeclineTjenesteleverandorOppdrag', () => ({ default: true }), {
    virtual: true
});
jest.mock(
    '@salesforce/apex/HOT_TjenesteleverandorListController.getTransferredServiceAppointments',
    () => {
        const { createApexTestWireAdapter } = require('@salesforce/sfdx-lwc-jest');
        return { default: createApexTestWireAdapter(jest.fn()) };
    },
    { virtual: true }
);
jest.mock(
    '@salesforce/apex/HOT_TjenesteleverandorAcceptanceService.acceptServiceAppointments',
    () => ({ default: jest.fn() }),
    { virtual: true }
);

const CHECKED_ROWS_STORAGE_KEY = 'tjenesteleverandorTransferredCheckedRows';
const LIST_REFRESH_KEY = 'tjenesteleverandorTransferredListRefresh';
const ACCEPTED_LIST_REFRESH_KEY = 'tjenesteleverandorAcceptedListRefresh';
const flushPromises = () => new Promise((resolve) => setTimeout(resolve, 0));

const APPOINTMENTS = [
    {
        Id: '08p000000000001AAA',
        EarliestStartTime: '2099-08-01T08:00:00.000Z',
        DueDate: '2099-08-01T09:00:00.000Z',
        AppointmentNumber: 'SA-0001',
        HOT_FreelanceSubject__c: 'Tema 1',
        HOT_WorkTypeName__c: 'TS - Tegnspråk',
        HOT_AssignmentType__c: 'Helsetjenester',
        HOT_ServiceTerritoryDeveloperName__c: 'Oslo',
        HOT_ServiceTerritoryName__c: 'Oslo',
        HOT_Request__c: 'a0R000000000001AAA',
        HOT_IsSerieoppdrag__c: true,
        HOT_IsOtherEconomicProvicer__c: false,
        HOT_TjenesteleverandorDeadline__c: '2099-07-31T10:00:00.000Z'
    },
    {
        Id: '08p000000000002AAA',
        EarliestStartTime: '2099-08-02T10:00:00.000Z',
        DueDate: '2099-08-02T11:00:00.000Z',
        AppointmentNumber: 'SA-0002',
        HOT_FreelanceSubject__c: 'Tema 2',
        HOT_WorkTypeName__c: 'SK - Skrivetolking',
        HOT_AssignmentType__c: 'Utdanning',
        HOT_ServiceTerritoryDeveloperName__c: 'Ost_Viken',
        HOT_ServiceTerritoryName__c: 'Øst-Viken',
        HOT_Request__c: 'a0R000000000001AAA',
        HOT_IsSerieoppdrag__c: true,
        HOT_IsOtherEconomicProvicer__c: true,
        HOT_TjenesteleverandorDeadline__c: '2099-08-01T10:00:00.000Z'
    }
];

function createComponent() {
    const element = createElement('c-hot-tjenesteleverandor-sa-transferred-list', {
        is: HotTjenesteleverandorSaTransferredList
    });
    document.body.appendChild(element);
    return element;
}

async function createLoadedComponent() {
    const element = createComponent();
    getTransferredServiceAppointments.emit(APPOINTMENTS);
    await flushPromises();
    return element;
}

function selectRows(element, recordIds) {
    element.shadowRoot
        .querySelector('c-hot_freelance-common-table')
        .dispatchEvent(new CustomEvent('checkedrows', { detail: { checkedRows: recordIds } }));
}

describe('c-hot-tjenesteleverandor-sa-transferred-list', () => {
    beforeEach(() => {
        sessionStorage.clear();
        HTMLDialogElement.prototype.showModal = jest.fn();
    });

    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        refreshApex.mockClear();
        Navigate.mockClear();
        acceptServiceAppointments.mockReset();
    });

    it('renders transferred appointments and their calculated presentation values', async () => {
        const element = await createLoadedComponent();
        const table = element.shadowRoot.querySelector('c-hot_freelance-common-table');

        expect(table.records).toHaveLength(2);
        expect(table.records[0].StartAndEndDate).toBeTruthy();
        expect(table.records[0].isOtherProvider).toBe('Nei');
        expect(table.records[1].isOtherProvider).toBe('Ja');
        expect(element.shadowRoot.textContent).toContain('0 oppdrag valgt');
    });

    it('refreshes the cached wire when returning after a single response', async () => {
        const element = await createLoadedComponent();
        refreshApex.mockResolvedValue();
        sessionStorage.setItem(LIST_REFRESH_KEY, 'single-response');

        window.dispatchEvent(new PopStateEvent('popstate'));
        await flushPromises();

        expect(refreshApex).toHaveBeenCalledTimes(1);
        expect(sessionStorage.getItem(LIST_REFRESH_KEY)).toBeNull();
        expect(element.shadowRoot.querySelector('c-hot_loader')).toBeNull();
    });

    it('shows a bulk confirmation and preserves selection when the user goes back', async () => {
        const element = await createLoadedComponent();
        selectRows(
            element,
            APPOINTMENTS.map((appointment) => appointment.Id)
        );
        await flushPromises();

        element.shadowRoot
            .querySelector('[data-id="start-bulk-acceptance"]')
            .dispatchEvent(new CustomEvent('buttonclick'));
        await flushPromises();

        const review = element.shadowRoot.querySelector('c-hot_tjenesteleverandor-bulk-acceptance');
        expect(review.appointments).toHaveLength(2);
        expect(review.action).toBe('accept');

        review.dispatchEvent(new CustomEvent('cancel'));
        await flushPromises();

        expect(element.shadowRoot.querySelector('c-hot_freelance-common-table').checkedRows).toEqual(
            APPOINTMENTS.map((appointment) => appointment.Id)
        );
        expect(JSON.parse(sessionStorage.getItem(CHECKED_ROWS_STORAGE_KEY))).toEqual(
            APPOINTMENTS.map((appointment) => appointment.Id)
        );
    });

    it('filters transferred appointments by region and removes hidden selections', async () => {
        const element = await createLoadedComponent();
        selectRows(
            element,
            APPOINTMENTS.map((appointment) => appointment.Id)
        );
        const filters = createDefaultFilters();
        const regionFilter = filters.find((filter) => filter.name === 'HOT_ServiceTerritoryDeveloperName__c');
        regionFilter.value.find((region) => region.name === 'Oslo').value = true;

        const filteredRecordsLength = element.applyFilter({
            detail: { filterArray: filters, setRecords: true }
        });
        await flushPromises();

        const table = element.shadowRoot.querySelector('c-hot_freelance-common-table');
        expect(filteredRecordsLength).toBe(1);
        expect(table.records.map((record) => record.Id)).toEqual([APPOINTMENTS[0].Id]);
        expect(table.checkedRows).toEqual([APPOINTMENTS[0].Id]);
        expect(JSON.parse(sessionStorage.getItem(CHECKED_ROWS_STORAGE_KEY))).toEqual([APPOINTMENTS[0].Id]);
    });

    it('keeps only failed rows selected after a partial bulk result and refreshes the wire', async () => {
        const element = await createLoadedComponent();
        selectRows(
            element,
            APPOINTMENTS.map((appointment) => appointment.Id)
        );
        await flushPromises();
        element.shadowRoot
            .querySelector('[data-id="start-bulk-acceptance"]')
            .dispatchEvent(new CustomEvent('buttonclick'));
        await flushPromises();

        element.shadowRoot.querySelector('c-hot_tjenesteleverandor-bulk-acceptance').dispatchEvent(
            new CustomEvent('responsecomplete', {
                detail: {
                    action: 'accept',
                    results: [
                        { recordId: APPOINTMENTS[0].Id, success: true },
                        {
                            recordId: APPOINTMENTS[1].Id,
                            success: false,
                            message: 'Oppdraget er ikke lenger tilgjengelig.'
                        }
                    ]
                }
            })
        );
        await flushPromises();

        expect(refreshApex).toHaveBeenCalledTimes(1);
        expect(JSON.parse(sessionStorage.getItem(CHECKED_ROWS_STORAGE_KEY))).toEqual([APPOINTMENTS[1].Id]);
        expect(sessionStorage.getItem(ACCEPTED_LIST_REFRESH_KEY)).not.toBeNull();
        expect(element.shadowRoot.textContent).toContain('1 oppdrag ble akseptert.');
        expect(element.shadowRoot.textContent).toContain('1 kunne ikke aksepteres');
    });

    it('shows bulk decline confirmation and reports a successful decline', async () => {
        const element = await createLoadedComponent();
        selectRows(
            element,
            APPOINTMENTS.map((appointment) => appointment.Id)
        );
        await flushPromises();

        element.shadowRoot
            .querySelector('[data-id="start-bulk-decline"]')
            .dispatchEvent(new CustomEvent('buttonclick'));
        await flushPromises();

        const review = element.shadowRoot.querySelector('c-hot_tjenesteleverandor-bulk-acceptance');
        expect(review.appointments).toHaveLength(2);
        expect(review.action).toBe('decline');

        review.dispatchEvent(
            new CustomEvent('responsecomplete', {
                detail: {
                    action: 'decline',
                    results: APPOINTMENTS.map((appointment) => ({
                        recordId: appointment.Id,
                        success: true,
                        message: 'Oppdraget er avslått.'
                    }))
                }
            })
        );
        await flushPromises();

        expect(refreshApex).toHaveBeenCalledTimes(1);
        expect(JSON.parse(sessionStorage.getItem(CHECKED_ROWS_STORAGE_KEY))).toEqual([]);
        expect(sessionStorage.getItem(ACCEPTED_LIST_REFRESH_KEY)).toBeNull();
        expect(element.shadowRoot.textContent).toContain('2 oppdrag ble avslått.');
    });

    it('opens the existing modal and routes Vis mer info to the separate Experience page', async () => {
        const element = await createLoadedComponent();
        element.shadowRoot
            .querySelector('c-hot_freelance-common-table')
            .dispatchEvent(new CustomEvent('rowclick', { detail: APPOINTMENTS[0] }));
        await flushPromises();

        expect(HTMLDialogElement.prototype.showModal).toHaveBeenCalledTimes(1);
        expect(element.shadowRoot.querySelector('.modal-body').textContent).toContain('SA-0001');
        expect(element.shadowRoot.querySelector('.series-container c-hot_freelance-common-table').records).toHaveLength(
            2
        );

        element.shadowRoot.querySelector('.modal-footer c-button').dispatchEvent(new CustomEvent('buttonclick'));
        await flushPromises();

        expect(Navigate).toHaveBeenCalledWith(
            {
                type: 'comm__namedPage',
                attributes: { name: 'Oppdragsdetaljer__c' },
                state: { c__recordId: APPOINTMENTS[0].Id }
            },
            undefined
        );
        expect(element.shadowRoot.querySelector('.modal-body')).toBeNull();
    });

    it('does not show appointments with the same request as a series when the selected appointment is not a series', async () => {
        const nonSeriesAppointments = APPOINTMENTS.map((appointment) => ({
            ...appointment,
            HOT_IsSerieoppdrag__c: false
        }));
        const element = createComponent();
        getTransferredServiceAppointments.emit(nonSeriesAppointments);
        await flushPromises();

        element.shadowRoot
            .querySelector('c-hot_freelance-common-table')
            .dispatchEvent(new CustomEvent('rowclick', { detail: nonSeriesAppointments[0] }));
        await flushPromises();

        expect(HTMLDialogElement.prototype.showModal).toHaveBeenCalledTimes(1);
        expect(element.shadowRoot.querySelector('.modal-body').textContent).toContain('SA-0001');
        expect(element.shadowRoot.querySelector('.series-container')).toBeNull();
    });
});
