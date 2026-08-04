import { createElement } from 'lwc';
import { registerApexTestWireAdapter } from '@salesforce/sfdx-lwc-jest';
import HotTjenesteleverandorSaAcceptedList from 'c/hot_tjenesteleverandorSaAcceptedList';
import getAcceptedServiceAppointments from '@salesforce/apex/HOT_TjenesteleverandorListController.getAcceptedServiceAppointments';
import { Navigate } from 'lightning/navigation';

jest.mock(
    '@salesforce/apex/HOT_TjenesteleverandorListController.getAcceptedServiceAppointments',
    () => ({ default: jest.fn() }),
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

const acceptedAppointmentsAdapter = registerApexTestWireAdapter(getAcceptedServiceAppointments);
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
        acceptedAppointmentsAdapter.emit([APPOINTMENT]);
        await flushPromises();

        const table = element.shadowRoot.querySelector('c-hot_freelance-common-table');
        expect(table.records).toHaveLength(1);
        expect(table.records[0].isOtherProvider).toBe('Ja');
        expect(element.shadowRoot.querySelector('c-hot_loader')).toBeNull();
    });

    it('opens the existing modal and routes Vis mer info to the separate Experience page', async () => {
        const element = createComponent();
        acceptedAppointmentsAdapter.emit([APPOINTMENT]);
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
