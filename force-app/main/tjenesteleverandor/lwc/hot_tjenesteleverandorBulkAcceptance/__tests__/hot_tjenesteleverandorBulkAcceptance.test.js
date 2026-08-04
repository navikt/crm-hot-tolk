import { createElement } from 'lwc';
import HotTjenesteleverandorBulkAcceptance from 'c/hot_tjenesteleverandorBulkAcceptance';
import acceptServiceAppointments from '@salesforce/apex/HOT_TjenesteleverandorAcceptanceService.acceptServiceAppointments';

jest.mock(
    '@salesforce/apex/HOT_TjenesteleverandorAcceptanceService.acceptServiceAppointments',
    () => ({ default: jest.fn() }),
    { virtual: true }
);

const APPOINTMENTS = [
    {
        Id: '08p000000000001AAA',
        HOT_ServiceAppointmentNumber__c: 'SA-0001',
        StartAndEndDate: '01.08.2099, 10:00 - 11:00',
        HOT_FreelanceSubject__c: 'Tema 1',
        HOT_WorkTypeName__c: 'Tegnspråk',
        HOT_ServiceTerritoryName__c: 'Oslo',
        TjenesteleverandorDeadline: '31.07.2099, 12:00'
    },
    {
        Id: '08p000000000002AAA',
        HOT_ServiceAppointmentNumber__c: 'SA-0002',
        StartAndEndDate: '02.08.2099, 12:00 - 13:00',
        HOT_FreelanceSubject__c: 'Tema 2',
        HOT_WorkTypeName__c: 'Skrivetolking',
        HOT_ServiceTerritoryName__c: 'Øst-Viken',
        TjenesteleverandorDeadline: '01.08.2099, 12:00'
    }
];

const flushPromises = () => new Promise((resolve) => setTimeout(resolve, 0));

function createComponent(appointments = APPOINTMENTS) {
    const element = createElement('c-hot-tjenesteleverandor-bulk-acceptance', {
        is: HotTjenesteleverandorBulkAcceptance
    });
    element.appointments = appointments;
    document.body.appendChild(element);
    return element;
}

describe('c-hot-tjenesteleverandor-bulk-acceptance', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        acceptServiceAppointments.mockReset();
    });

    it('shows a confirmation table containing the selected appointments', () => {
        const element = createComponent();

        const rows = element.shadowRoot.querySelectorAll('tbody tr');
        expect(rows).toHaveLength(2);
        expect(element.shadowRoot.textContent).toContain('2 oppdrag er valgt.');
        expect(element.shadowRoot.textContent).toContain('SA-0001');
        expect(element.shadowRoot.textContent).toContain('Tegnspråk');
        expect(element.shadowRoot.textContent).toContain('31.07.2099, 12:00');
    });

    it('returns to the list without accepting when Tilbake is selected', () => {
        const element = createComponent();
        const cancelHandler = jest.fn();
        element.addEventListener('cancel', cancelHandler);

        element.shadowRoot.querySelector('c-button').dispatchEvent(new CustomEvent('buttonclick'));

        expect(cancelHandler).toHaveBeenCalledTimes(1);
        expect(acceptServiceAppointments).not.toHaveBeenCalled();
    });

    it('accepts all reviewed IDs and returns per-record outcomes to the list', async () => {
        const results = APPOINTMENTS.map((appointment) => ({
            recordId: appointment.Id,
            success: true,
            message: 'Oppdraget er akseptert.'
        }));
        acceptServiceAppointments.mockResolvedValue(results);
        const element = createComponent();
        const completeHandler = jest.fn();
        element.addEventListener('acceptcomplete', completeHandler);

        element.shadowRoot
            .querySelector('[data-id="confirm-bulk-acceptance"]')
            .dispatchEvent(new CustomEvent('buttonclick'));
        await flushPromises();

        expect(acceptServiceAppointments).toHaveBeenCalledWith({
            serviceAppointmentIds: APPOINTMENTS.map((appointment) => appointment.Id)
        });
        expect(completeHandler).toHaveBeenCalledWith(expect.objectContaining({ detail: { results } }));
    });

    it('disables bulk acceptance when no appointments are provided', () => {
        const element = createComponent([]);

        expect(element.shadowRoot.querySelector('[data-id="confirm-bulk-acceptance"]').disabled).toBe(true);
    });

    it('shows a handled server error and remains on the confirmation page', async () => {
        acceptServiceAppointments.mockRejectedValue({
            body: { message: 'Du har ikke tilgang til å akseptere oppdrag.' }
        });
        const element = createComponent();

        element.shadowRoot
            .querySelector('[data-id="confirm-bulk-acceptance"]')
            .dispatchEvent(new CustomEvent('buttonclick'));
        await flushPromises();

        expect(element.shadowRoot.textContent).toContain('Du har ikke tilgang til å akseptere oppdrag.');
        expect(element.shadowRoot.querySelectorAll('tbody tr')).toHaveLength(2);
    });
});
