import { createElement } from 'lwc';
import HotCalendarV2 from 'c/hot_calendar_v2';
import getCalendarEvents from '@salesforce/apex/HOT_FullCalendarController.getCalendarEvents';
import getOpenServiceAppointments from '@salesforce/apex/HOT_OpenServiceAppointmentListController.getOpenServiceAppointments';
import createInterestedResources from '@salesforce/apex/HOT_OpenServiceAppointmentListController.createInterestedResources';
import getServiceResource from '@salesforce/apex/HOT_FreelanceUserInformationController.getServiceResource';
import checkAccessToSA from '@salesforce/apex/HOT_MyServiceAppointmentListController.checkAccessToSA';

jest.mock('@salesforce/apex/HOT_FullCalendarController.getCalendarEvents', () => ({ default: jest.fn() }), {
    virtual: true
});
jest.mock(
    '@salesforce/apex/HOT_OpenServiceAppointmentListController.getOpenServiceAppointments',
    () => ({ default: jest.fn() }),
    { virtual: true }
);
jest.mock(
    '@salesforce/apex/HOT_OpenServiceAppointmentListController.createInterestedResources',
    () => ({ default: jest.fn() }),
    { virtual: true }
);
jest.mock(
    '@salesforce/apex/HOT_FreelanceUserInformationController.getServiceResource',
    () => ({ default: jest.fn() }),
    { virtual: true }
);
jest.mock('@salesforce/apex/HOT_MyServiceAppointmentListController.checkAccessToSA', () => ({ default: jest.fn() }), {
    virtual: true
});

const SERVICE_APPOINTMENT_ID = '08p000000000001AAA';
const OPEN_SERVICE_APPOINTMENT = {
    Id: SERVICE_APPOINTMENT_ID,
    EarliestStartTime: '2026-08-10T08:00:00.000Z',
    DueDate: '2026-08-10T10:00:00.000Z',
    HOT_ServiceAppointmentNumber__c: 'SA-0001',
    HOT_FreelanceSubject__c: 'Tolkebistand',
    HOT_AddressFormated__c: 'Testveien 1, Oslo',
    HOT_WorkTypeName__c: 'Oppmøte',
    HOT_PreparationTime__c: '30 minutter',
    HOT_AssignmentType__c: 'Frilans',
    HOT_NumberOfInterestedResources__c: 1,
    HOT_ServiceTerritoryName__c: 'Oslo',
    HOT_DeadlineDate__c: '2026-08-09',
    HOT_Request__r: {
        IsOtherEconomicProvicer__c: false,
        OwnerName__c: 'NAV Tolketjenesten'
    }
};

const flushPromises = () => new Promise((resolve) => setTimeout(resolve, 0));

let calendarInstance;

class CalendarMock {
    constructor(element, config) {
        this.element = element;
        this.config = config;
        this.events = [...config.events];
        this.view = {
            type: 'dayGridMonth',
            activeStart: new Date('2026-08-01T00:00:00.000Z'),
            currentStart: new Date('2026-08-01T00:00:00.000Z')
        };
        calendarInstance = this;
    }

    render() {}

    getDate() {
        return new Date('2026-08-10T00:00:00.000Z');
    }

    getEvents() {
        return this.events;
    }

    addEvent(event) {
        this.events.push(event);
    }

    removeAllEvents() {
        this.events = [];
    }

    batchRendering(callback) {
        callback();
    }

    setOption() {}

    changeView() {}
}

function getButton(element, label) {
    return [...element.shadowRoot.querySelectorAll('c-button')].find((button) => button.buttonLabel === label);
}

function dispatchButtonClick(button) {
    button.dispatchEvent(new CustomEvent('buttonclick'));
}

async function createCalendar() {
    const element = createElement('c-hot-calendar-v2', { is: HotCalendarV2 });
    document.body.appendChild(element);
    await flushPromises();
    await flushPromises();
    return element;
}

async function openEvent(element, type, recordId = SERVICE_APPOINTMENT_ID) {
    calendarInstance.config.eventClick({
        view: { type: 'timeGridDay' },
        event: {
            id: '',
            start: new Date('2026-08-10T08:00:00.000Z'),
            extendedProps: { type, recordId }
        }
    });
    await flushPromises();
    await flushPromises();
    return element;
}

describe('c-hot-calendar-v2 open service appointment interest', () => {
    beforeAll(() => {
        Object.defineProperty(HTMLDialogElement.prototype, 'showModal', {
            configurable: true,
            value() {
                this.setAttribute('open', '');
            }
        });
        Object.defineProperty(HTMLDialogElement.prototype, 'close', {
            configurable: true,
            value() {
                this.removeAttribute('open');
            }
        });
    });

    beforeEach(() => {
        global.FullCalendar = { Calendar: CalendarMock };
        getServiceResource.mockResolvedValue({ HOT_ShowOpenServiceAppointmentEvents__c: true });
        getCalendarEvents.mockResolvedValue([]);
        getOpenServiceAppointments.mockResolvedValue([OPEN_SERVICE_APPOINTMENT]);
        createInterestedResources.mockResolvedValue();
        checkAccessToSA.mockResolvedValue(false);
    });

    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        sessionStorage.clear();
        jest.clearAllMocks();
        calendarInstance = undefined;
        delete global.FullCalendar;
    });

    it('shows Meld interesse only for open service appointments', async () => {
        const element = await createCalendar();

        await openEvent(element, 'OPEN_SERVICE_APPOINTMENT');

        expect(getButton(element, 'Meld interesse')).toBeTruthy();

        const secondElement = await createCalendar();
        await openEvent(secondElement, 'SERVICE_APPOINTMENT');

        expect(getButton(secondElement, 'Meld interesse')).toBeUndefined();
    });

    it('submits one appointment with a message and refreshes the calendar', async () => {
        let resolveSubmission;
        createInterestedResources.mockReturnValue(
            new Promise((resolve) => {
                resolveSubmission = resolve;
            })
        );
        const calendarEvent = {
            extendedProps: { recordId: SERVICE_APPOINTMENT_ID },
            remove: jest.fn()
        };
        const element = await createCalendar();
        await openEvent(element, 'OPEN_SERVICE_APPOINTMENT');
        calendarInstance.events = [calendarEvent];

        dispatchButtonClick(getButton(element, 'Meld interesse'));
        await flushPromises();

        const commentField = element.shadowRoot.querySelector('.comment-field');
        commentField.value = 'Jeg kan ta oppdraget.';
        commentField.dispatchEvent(new CustomEvent('change', { detail: { value: commentField.value } }));
        dispatchButtonClick(getButton(element, 'Send inn'));
        dispatchButtonClick(getButton(element, 'Send inn'));

        expect(createInterestedResources).toHaveBeenCalledTimes(1);
        expect(createInterestedResources).toHaveBeenCalledWith({
            serviceAppointmentIds: [SERVICE_APPOINTMENT_ID],
            comments: ['Jeg kan ta oppdraget.']
        });

        await flushPromises();
        expect(element.shadowRoot.querySelector('.modal-header h2').hidden).toBe(true);
        expect(element.shadowRoot.querySelector('.interest-status').textContent).toContain('Melder interesse...');

        resolveSubmission();
        await flushPromises();
        await flushPromises();

        expect(calendarEvent.remove).toHaveBeenCalled();
        expect(getCalendarEvents).toHaveBeenCalledTimes(2);
        expect(element.shadowRoot.querySelector('.interest-status').textContent).toContain('Interesse er meldt.');
    });

    it('allows registration without a message', async () => {
        const element = await createCalendar();
        await openEvent(element, 'OPEN_SERVICE_APPOINTMENT');

        dispatchButtonClick(getButton(element, 'Meld interesse'));
        await flushPromises();
        dispatchButtonClick(getButton(element, 'Send inn'));
        await flushPromises();
        await flushPromises();

        expect(createInterestedResources).toHaveBeenCalledWith({
            serviceAppointmentIds: [SERVICE_APPOINTMENT_ID],
            comments: ['']
        });
    });

    it('keeps the message and permits retry after an error', async () => {
        createInterestedResources.mockRejectedValueOnce({ body: { message: 'Oppdraget kunne ikke oppdateres.' } });
        const element = await createCalendar();
        await openEvent(element, 'OPEN_SERVICE_APPOINTMENT');

        dispatchButtonClick(getButton(element, 'Meld interesse'));
        await flushPromises();

        let commentField = element.shadowRoot.querySelector('.comment-field');
        commentField.value = 'Ta kontakt med meg.';
        commentField.dispatchEvent(new CustomEvent('change', { detail: { value: commentField.value } }));
        dispatchButtonClick(getButton(element, 'Send inn'));
        await flushPromises();
        await flushPromises();

        expect(element.shadowRoot.querySelector('.interest-error').textContent).toContain(
            'Oppdraget kunne ikke oppdateres.'
        );
        commentField = element.shadowRoot.querySelector('.comment-field');
        expect(commentField.value).toBe('Ta kontakt med meg.');

        createInterestedResources.mockResolvedValueOnce();
        dispatchButtonClick(getButton(element, 'Send inn'));
        await flushPromises();
        await flushPromises();

        expect(createInterestedResources).toHaveBeenCalledTimes(2);
        expect(element.shadowRoot.querySelector('.interest-status').textContent).toContain('Interesse er meldt.');
    });
});
