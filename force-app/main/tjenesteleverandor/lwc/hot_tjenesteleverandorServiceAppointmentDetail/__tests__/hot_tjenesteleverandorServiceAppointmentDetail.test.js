import { createElement } from 'lwc';
import { registerLdsTestWireAdapter } from '@salesforce/wire-service-jest-util';
import HotTjenesteleverandorServiceAppointmentDetail from 'c/hot_tjenesteleverandorServiceAppointmentDetail';
import { CurrentPageReference, Navigate } from 'lightning/navigation';
import { getRecord, notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import acceptServiceAppointments from '@salesforce/apex/HOT_TjenesteleverandorAcceptanceService.acceptServiceAppointments';
import declineServiceAppointments from '@salesforce/apex/HOT_TjenesteleverandorAcceptanceService.declineServiceAppointments';

jest.mock('c/hot_sharedFonts', () => ({ __esModule: true, default: [] }), { virtual: true });
jest.mock('@salesforce/customPermission/HOT_AcceptTjenesteleverandorOppdrag', () => ({ default: true }), {
    virtual: true
});
jest.mock('@salesforce/customPermission/HOT_DeclineTjenesteleverandorOppdrag', () => ({ default: true }), {
    virtual: true
});
jest.mock(
    '@salesforce/apex/HOT_TjenesteleverandorAcceptanceService.acceptServiceAppointments',
    () => ({ default: jest.fn() }),
    { virtual: true }
);
jest.mock(
    '@salesforce/apex/HOT_TjenesteleverandorAcceptanceService.declineServiceAppointments',
    () => ({ default: jest.fn() }),
    { virtual: true }
);

const getRecordAdapter = registerLdsTestWireAdapter(getRecord);

const RECORD_ID = '08p000000000001AAA';
const TRANSFERRED_LIST_REFRESH_KEY = 'tjenesteleverandorTransferredListRefresh';
const ACCEPTED_LIST_REFRESH_KEY = 'tjenesteleverandorAcceptedListRefresh';
const flushPromises = () => new Promise((resolve) => setTimeout(resolve, 0));

function createComponent() {
    const element = createElement('c-hot-tjenesteleverandor-service-appointment-detail', {
        is: HotTjenesteleverandorServiceAppointmentDetail
    });
    element.recordId = RECORD_ID;
    document.body.appendChild(element);
    return element;
}

function emitRecord(fieldOverrides = {}) {
    getRecordAdapter.emit({
        id: RECORD_ID,
        apiName: 'ServiceAppointment',
        fields: {
            AppointmentNumber: { value: 'SA-482649' },
            HOT_FreelanceSubject__c: { value: 'Testing' },
            HOT_Information__c: { value: '1TS, SO3 -' },
            HOT_WorkTypeName__c: { value: 'TS - Tegnspråk' },
            HOT_AssignmentType__c: { value: 'Dagligliv' },
            HOT_PreparationTime__c: { value: '0' },
            HOT_TotalNumberOfInterpreters__c: { value: 1 },
            HOT_NumberOfInterestedResources__c: { value: 1 },
            Status: { value: 'Released to Freelance' },
            HOT_TjenesteleverandorStatus__c: { value: 'Transferred' },
            HOT_ServiceTerritoryName__c: { value: 'Troms og Finnmark' },
            HOT_IsAcute__c: { value: true },
            HOT_IsScreenInterpreterNew__c: { value: true },
            HOT_IsSerieoppdrag__c: { value: true },
            HOT_IsOtherEconomicProvicer__c: { value: false },
            HOT_IsImageInterpreter__c: { value: true },
            HOT_DayOfWeek__c: { value: 'Fredag' },
            HOT_AddressFormated__c: { value: 'NAV Oslo' },
            HOT_IsReleasedToFreelance__c: { value: true },
            HOT_TjenesteleverandorDeadline__c: { value: '2099-08-01T12:00:00.000Z' },
            EarliestStartTime: { value: '2099-08-01T08:00:00.000Z' },
            DueDate: { value: '2099-08-01T10:00:00.000Z' },
            HOT_CancelComment__c: { value: null },
            HOT_CanceledByInterpreter__c: { value: false },
            HOT_CanceledDate__c: { value: null },
            HOT_LateCancellation__c: { value: false },
            ...fieldOverrides
        }
    });
}

function getCancellationSection(element) {
    return [...element.shadowRoot.querySelectorAll('h2')].find((heading) => heading.textContent === 'Avlysning')
        ?.parentElement;
}

describe('c-hot-tjenesteleverandor-service-appointment-detail', () => {
    beforeEach(() => {
        sessionStorage.clear();
    });

    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        Navigate.mockClear();
        notifyRecordUpdateAvailable.mockClear();
        acceptServiceAppointments.mockReset();
        declineServiceAppointments.mockReset();
        jest.restoreAllMocks();
        delete window.history.length;
    });

    it('shows a loading state until wire data is available', () => {
        const element = createComponent();

        expect(element.shadowRoot.querySelector('lightning-spinner')).not.toBeNull();
        expect(element.shadowRoot.querySelector('.detail-layout')).toBeNull();
    });

    it('reads appointment ID from Experience page route state', async () => {
        const element = createElement('c-hot-tjenesteleverandor-service-appointment-detail', {
            is: HotTjenesteleverandorServiceAppointmentDetail
        });
        document.body.appendChild(element);

        CurrentPageReference.emit({
            state: {
                c__recordId: RECORD_ID
            }
        });
        await flushPromises();

        expect(getRecordAdapter.getLastConfig().recordId).toBe(RECORD_ID);
        emitRecord();
        await flushPromises();
        expect(element.shadowRoot.textContent).toContain('SA-482649');
    });

    it('renders custom wire-driven appointment detail sections', async () => {
        const element = createComponent();

        emitRecord();
        await flushPromises();

        expect(element.shadowRoot.querySelector('lightning-spinner')).toBeNull();
        expect(element.shadowRoot.textContent).toContain('Oppdragsdetaljer');
        expect(element.shadowRoot.textContent).toContain('Bestilt tid');
        expect(element.shadowRoot.textContent).not.toContain('Tildelte ressurser');
        expect(element.shadowRoot.querySelector('.resource-panel')).toBeNull();
        expect(element.shadowRoot.querySelectorAll('.detail-layout .detail-card')).toHaveLength(2);
        expect(element.shadowRoot.textContent).toContain('Akuttvaktoppdrag');
        expect(element.shadowRoot.textContent).toContain('Bildetolk');
        expect(element.shadowRoot.textContent).toContain('Skjermtolk');
        expect(element.shadowRoot.textContent).toContain('Serieoppdrag');
    });

    it('groups the ordered time labels and values in a description list', async () => {
        const element = createComponent();
        emitRecord();
        await flushPromises();

        const timeGrid = element.shadowRoot.querySelector('dl.time-grid');
        expect([...timeGrid.querySelectorAll('dt')].map((label) => label.textContent)).toEqual([
            'Bestilt starttid',
            'Bestilt sluttid',
            'Varighet',
            'Ukedag'
        ]);
        expect(timeGrid.querySelectorAll('dd')).toHaveLength(4);
        const dates = timeGrid.querySelectorAll('lightning-formatted-date-time');
        expect(dates[0].value).toBe('2099-08-01T08:00:00.000Z');
        expect(dates[1].value).toBe('2099-08-01T10:00:00.000Z');
        expect(dates[0].hour).toBe('2-digit');
        expect(dates[1].minute).toBe('2-digit');
    });

    it('shows cancellation details when cancellation values are populated', async () => {
        const element = createComponent();

        emitRecord({
            HOT_CancelComment__c: { value: 'Avlyst av bestiller' }
        });
        await flushPromises();

        expect(getCancellationSection(element)).not.toBeUndefined();
        expect(element.shadowRoot.textContent).toContain('Avlyst av bestiller');
    });

    it('accepts a single appointment and refreshes the record', async () => {
        acceptServiceAppointments.mockResolvedValue([
            {
                recordId: RECORD_ID,
                success: true,
                message: 'Oppdraget er akseptert.'
            }
        ]);
        const element = createComponent();
        emitRecord();
        await flushPromises();

        element.shadowRoot
            .querySelector('[data-id="accept-appointment"]')
            .dispatchEvent(new CustomEvent('buttonclick'));
        await flushPromises();
        await flushPromises();

        expect(acceptServiceAppointments).toHaveBeenCalledWith({
            serviceAppointmentIds: [RECORD_ID]
        });
        expect(notifyRecordUpdateAvailable).toHaveBeenCalledWith([{ recordId: RECORD_ID }]);
        expect(element.shadowRoot.querySelector('[data-id="accept-appointment"]')).toBeNull();
        expect(element.shadowRoot.textContent).toContain('Oppdraget er akseptert.');
        expect(sessionStorage.getItem(TRANSFERRED_LIST_REFRESH_KEY)).not.toBeNull();
        expect(sessionStorage.getItem(ACCEPTED_LIST_REFRESH_KEY)).not.toBeNull();
    });

    it('declines a single appointment and refreshes the record', async () => {
        declineServiceAppointments.mockResolvedValue([
            {
                recordId: RECORD_ID,
                success: true,
                message: 'Oppdraget er avslått.'
            }
        ]);
        const element = createComponent();
        emitRecord();
        await flushPromises();

        element.shadowRoot
            .querySelector('[data-id="decline-appointment"]')
            .dispatchEvent(new CustomEvent('buttonclick'));
        await flushPromises();
        await flushPromises();

        expect(declineServiceAppointments).toHaveBeenCalledWith({
            serviceAppointmentIds: [RECORD_ID]
        });
        expect(acceptServiceAppointments).not.toHaveBeenCalled();
        expect(notifyRecordUpdateAvailable).toHaveBeenCalledWith([{ recordId: RECORD_ID }]);
        expect(element.shadowRoot.querySelector('[data-id="decline-appointment"]')).toBeNull();
        expect(element.shadowRoot.textContent).toContain('Oppdraget er avslått.');
        expect(sessionStorage.getItem(TRANSFERRED_LIST_REFRESH_KEY)).not.toBeNull();
        expect(sessionStorage.getItem(ACCEPTED_LIST_REFRESH_KEY)).toBeNull();
    });

    it('shows generic error when wire returns an error', async () => {
        const element = createComponent();
        getRecordAdapter.error();
        await flushPromises();

        expect(element.shadowRoot.querySelector('lightning-spinner')).toBeNull();
        expect(element.shadowRoot.querySelector('.error-message').textContent).toContain(
            'Du har ikke tilgang til oppdraget, eller oppdraget finnes ikke.'
        );
    });

    it('renders a keyboard-focusable back button with a decorative arrow', () => {
        const element = createComponent();
        const button = element.shadowRoot.querySelector('nav button.back-button');
        const icon = button.querySelector('lightning-icon');

        expect(button.type).toBe('button');
        expect(button.textContent.trim()).toBe('Tilbake til oppdrag');
        expect(button.disabled).toBe(false);
        expect(icon.iconName).toBe('utility:back');
        expect(icon.getAttribute('aria-hidden')).toBe('true');
        button.focus();
        expect(element.shadowRoot.activeElement).toBe(button);
    });

    it('returns through browser history when a previous page exists', () => {
        Object.defineProperty(window.history, 'length', { configurable: true, value: 2 });
        const backSpy = jest.spyOn(window.history, 'back').mockImplementation(() => {});
        const element = createComponent();

        element.shadowRoot.querySelector('nav button.back-button').click();

        expect(backSpy).toHaveBeenCalledTimes(1);
        expect(Navigate).not.toHaveBeenCalled();
    });

    it('navigates to site home page when browser history is unavailable', () => {
        Object.defineProperty(window.history, 'length', { configurable: true, value: 1 });
        const element = createComponent();

        element.shadowRoot.querySelector('nav button.back-button').click();

        expect(Navigate).toHaveBeenCalledWith(
            {
                type: 'comm__namedPage',
                attributes: { name: 'home' }
            },
            undefined
        );
    });
});
