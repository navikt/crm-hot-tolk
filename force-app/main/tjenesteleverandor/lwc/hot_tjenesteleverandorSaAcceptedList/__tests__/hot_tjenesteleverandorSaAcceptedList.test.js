import { createElement } from 'lwc';
import HotTjenesteleverandorSaAcceptedList from 'c/hot_tjenesteleverandorSaAcceptedList';
import getAcceptedServiceAppointments from '@salesforce/apex/HOT_TjenesteleverandorListController.getAcceptedServiceAppointments';
import { refreshApex } from '@salesforce/apex';
import { Navigate } from 'lightning/navigation';

jest.mock(
    '@salesforce/apex/HOT_TjenesteleverandorListController.getAcceptedServiceAppointments',
    () => {
        const { createApexTestWireAdapter } = require('@salesforce/sfdx-lwc-jest');
        return { default: createApexTestWireAdapter(jest.fn()) };
    },
    { virtual: true }
);

const APPOINTMENT = {
    Id: '08p000000000001AAA',
    EarliestStartTime: '2099-08-01T08:00:00.000Z',
    DueDate: '2099-08-01T09:00:00.000Z',
    Status: 'Released to Freelance',
    AppointmentNumber: 'SA-0001',
    HOT_FreelanceSubject__c: 'Tema 1',
    HOT_WorkTypeName__c: 'Tegnspråk',
    HOT_ServiceTerritoryName__c: 'Oslo',
    HOT_IsOtherEconomicProvicer__c: true
};
const LIST_REFRESH_KEY = 'tjenesteleverandorAcceptedListRefresh';

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
        refreshApex.mockClear();
    });

    it('renders accepted appointments from the wire', async () => {
        const element = createComponent();
        getAcceptedServiceAppointments.emit([APPOINTMENT]);
        await flushPromises();

        const table = element.shadowRoot.querySelector('c-hot_freelance-common-table');
        expect(table.records).toHaveLength(1);
        expect(table.records[0].isOtherProvider).toBe('Ja');
        expect(element.shadowRoot.querySelector('c-hot_loader')).toBeNull();
    });

    it('refreshes the accepted wire after a single acceptance', async () => {
        const element = createComponent();
        getAcceptedServiceAppointments.emit([APPOINTMENT]);
        await flushPromises();
        refreshApex.mockResolvedValue();
        sessionStorage.setItem(LIST_REFRESH_KEY, 'single-acceptance');

        window.dispatchEvent(new PopStateEvent('popstate'));
        await flushPromises();

        expect(refreshApex).toHaveBeenCalledTimes(1);
        expect(sessionStorage.getItem(LIST_REFRESH_KEY)).toBeNull();
        expect(element.shadowRoot.querySelector('c-hot_loader')).toBeNull();
    });

    it('opens the existing modal and routes Vis mer info to the separate Experience page', async () => {
        const element = createComponent();
        getAcceptedServiceAppointments.emit([APPOINTMENT]);
        await flushPromises();

        element.shadowRoot
            .querySelector('c-hot_freelance-common-table')
            .dispatchEvent(new CustomEvent('rowclick', { detail: APPOINTMENT }));
        await flushPromises();

        expect(HTMLDialogElement.prototype.showModal).toHaveBeenCalledTimes(1);
        expect(element.shadowRoot.querySelector('.modal-body').textContent).toContain('SA-0001');

        element.shadowRoot.querySelector('.modal-footer c-button').dispatchEvent(new CustomEvent('buttonclick'));
        await flushPromises();

        expect(Navigate).toHaveBeenCalledWith(
            {
                type: 'comm__namedPage',
                attributes: { name: 'Oppdragsdetaljer__c' },
                state: { c__recordId: APPOINTMENT.Id }
            },
            undefined
        );
        expect(element.shadowRoot.querySelector('.modal-body')).toBeNull();
    });
});
