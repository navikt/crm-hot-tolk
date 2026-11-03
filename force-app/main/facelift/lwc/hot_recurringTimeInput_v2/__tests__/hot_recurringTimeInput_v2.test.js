import { createElement } from 'lwc';
import RecurringTimeInput from 'c/hot_recurringTimeInput_v2';
import getTimes from '@salesforce/apex/HOT_RequestListController.getTimesNew';
import previewRecurringWorkOrders from '@salesforce/apex/HOT_CreateWorkOrderService.previewRecurringWorkOrders';

jest.mock('c/input', () => require('../../../../../test/jest-mocks/c/input/input'), { virtual: true });
jest.mock('c/picklist', () => require('../../../../../test/jest-mocks/c/input/input'), { virtual: true });
jest.mock('c/checkboxgroup', () => require('../../../../../test/jest-mocks/c/input/input'), { virtual: true });
jest.mock('c/checkbox', () => require('../../../../../test/jest-mocks/c/input/input'));
jest.mock(
    '@salesforce/apex/HOT_RequestListController.getTimesNew',
    () => {
        const { createApexTestWireAdapter } = require('@salesforce/sfdx-lwc-jest');
        return { default: createApexTestWireAdapter(jest.fn()) };
    },
    { virtual: true }
);
jest.mock('@salesforce/apex/HOT_CreateWorkOrderService.previewRecurringWorkOrders', () => ({ default: jest.fn() }), {
    virtual: true
});

const flushPromises = async () => {
    await Promise.resolve();
    await Promise.resolve();
    await Promise.resolve();
};
const preview = {
    firstDate: '2027-10-31',
    lastDate: '2027-11-01',
    count: 2,
    timeZone: 'Europe/Paris',
    intervals: [
        {
            startTime: 1824935400000,
            endTime: 1824939000000,
            startLabel: '31.10.2027 00:30',
            endLabel: '31.10.2027 01:30'
        },
        {
            startTime: 1825025400000,
            endTime: 1825029000000,
            startLabel: '01.11.2027 00:30',
            endLabel: '01.11.2027 01:30'
        }
    ]
};

function change(element, selector, detail, name = 'getvalueonchange') {
    element.shadowRoot.querySelector(selector).dispatchEvent(new CustomEvent(name, { detail }));
}

async function setup(isEditMode = false) {
    const element = createElement('c-hot-recurring-time-input-v2', { is: RecurringTimeInput });
    element.isEditMode = isEditMode;
    document.body.appendChild(element);
    getTimes.emit([
        {
            id: isEditMode ? 'existing-work-order' : 0,
            date: '2027-10-30',
            startTime: new Date(2027, 9, 30, 0, 30).getTime(),
            endTime: new Date(2027, 9, 30, 1, 30).getTime()
        }
    ]);
    await flushPromises();
    element.shadowRoot.querySelectorAll('c-input').forEach((input) => {
        input.getValue = jest.fn(() => '09:00');
        input.setValue = jest.fn();
        input.sendErrorMessage = jest.fn();
    });
    change(element, 'c-checkbox', true, 'checkboxclick');
    await flushPromises();
    change(element, '[data-id="recurringType"]', { name: 'Weekly' }, 'picklistvaluechange');
    await flushPromises();
    change(element, '[data-id="recurringDays"]', [{ name: 'sunday', checked: true }], 'checkboxgroupclick');
    change(element, '[data-id="recurringEndDate"]', '2027-11-02');
    await flushPromises();
    element.shadowRoot.querySelector('[data-id="recurringEndDate"]').getValue = jest.fn(() => '2027-11-02');
    element.shadowRoot.querySelector('[data-id="recurringEndDate"]').sendErrorMessage = jest.fn();
    element.shadowRoot.querySelector('[data-id="recurringDays"]').getValue = jest.fn(() => [{ checked: true }]);
    element.shadowRoot.querySelector('[data-id="recurringDays"]').sendErrorMessage = jest.fn();
    return element;
}

describe('server recurrence preview', () => {
    beforeEach(() => {
        jest.useFakeTimers();
        previewRecurringWorkOrders.mockResolvedValue(preview);
    });

    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllTimers();
        jest.useRealTimers();
        jest.clearAllMocks();
    });

    it.each([false, true])('uses the saved timestamps and server boundaries in edit mode %s', async (editMode) => {
        const element = await setup(editMode);
        expect(previewRecurringWorkOrders).not.toHaveBeenCalled();
        jest.advanceTimersByTime(300);
        await flushPromises();
        const time = Object.values(element.getTimeInput().times)[0];
        expect(previewRecurringWorkOrders).toHaveBeenCalledWith({
            startTime: time.startTime,
            endTime: time.endTime,
            recurringEndDate: Date.parse('2027-11-02'),
            recurringType: 'Weekly',
            recurringDays: ['sunday']
        });
        expect(element.shadowRoot.querySelector('.recurring-boundary-warning').textContent).toContain(
            'første dato i serien 31.10.2027 og siste dato 01.11.2027'
        );
        const details = element.shadowRoot.querySelector('details');
        expect(details.open).toBe(false);
        expect(details.textContent).toContain('Europe/Paris');
        expect(details.querySelectorAll('tbody tr')).toHaveLength(2);
        expect(details.querySelector('tbody').textContent).toContain('01.11.2027 00:30');
        details.open = true;
        details.dispatchEvent(new Event('toggle'));
        await flushPromises();
        expect(details.querySelector('summary').textContent).toBe('Skjul tidspunkter');
    });

    it('debounces changes and clears a previous preview immediately', async () => {
        const element = await setup();
        jest.advanceTimersByTime(300);
        await flushPromises();
        change(element, '[data-id="recurringEndDate"]', '2027-11-03');
        await flushPromises();
        expect(element.shadowRoot.querySelector('details')).toBeNull();
        jest.advanceTimersByTime(200);
        change(element, '[data-id="recurringEndDate"]', '2027-11-04');
        jest.advanceTimersByTime(299);
        expect(previewRecurringWorkOrders).toHaveBeenCalledTimes(1);
        jest.advanceTimersByTime(1);
        await flushPromises();
        expect(previewRecurringWorkOrders).toHaveBeenCalledTimes(2);
        expect(previewRecurringWorkOrders.mock.calls[1][0].recurringEndDate).toBe(Date.parse('2027-11-04'));
    });

    it('ignores stale responses arriving after a newer response', async () => {
        let resolveFirst;
        previewRecurringWorkOrders.mockImplementationOnce(() => new Promise((resolve) => (resolveFirst = resolve)));
        const element = await setup();
        jest.advanceTimersByTime(300);
        change(element, '[data-id="recurringEndDate"]', '2027-11-04');
        jest.advanceTimersByTime(300);
        await flushPromises();
        resolveFirst({ ...preview, count: 0, intervals: [] });
        await flushPromises();
        expect(element.shadowRoot.querySelectorAll('tbody tr')).toHaveLength(2);
    });

    it('shows failures and allows a retry without changing form values', async () => {
        const log = jest.spyOn(console, 'error').mockImplementation(() => {});
        previewRecurringWorkOrders.mockRejectedValueOnce({ body: { message: 'Serverfeil' } });
        const element = await setup();
        jest.advanceTimersByTime(300);
        await flushPromises();
        expect(element.shadowRoot.querySelector('[role="alert"]').textContent).toBe('Serverfeil');
        change(element, 'c-button', null, 'buttonclick');
        jest.advanceTimersByTime(300);
        await flushPromises();
        expect(element.shadowRoot.querySelectorAll('tbody tr')).toHaveLength(2);
        log.mockRestore();
    });

    it('shows a server-reported empty series rather than calculating weekdays locally', async () => {
        previewRecurringWorkOrders.mockResolvedValue({ ...preview, count: 0, intervals: [] });
        const element = await setup();
        jest.advanceTimersByTime(300);
        await flushPromises();
        expect(element.shadowRoot.querySelector('[role="alert"]').textContent).toBe(
            'Valgte gjentagelsesdager finnes ikke i perioden.'
        );
        expect(element.shadowRoot.querySelector('details')).toBeNull();
    });

    it('does not request or display a preview when recurrence is switched off', async () => {
        const element = await setup();
        change(element, 'c-checkbox', false, 'checkboxclick');
        jest.advanceTimersByTime(300);
        await flushPromises();
        expect(previewRecurringWorkOrders).not.toHaveBeenCalled();
        expect(element.shadowRoot.querySelector('details')).toBeNull();
    });

    it('cancels a pending request when disconnected', async () => {
        const element = await setup();
        document.body.removeChild(element);
        jest.advanceTimersByTime(300);
        expect(previewRecurringWorkOrders).not.toHaveBeenCalled();
    });

    it('blocks submission while pending and clears the pending field error once ready', async () => {
        const element = await setup();
        expect(element.validateFields()).toBeGreaterThan(0);
        const endDate = element.shadowRoot.querySelector('[data-id="recurringEndDate"]');
        expect(endDate.sendErrorMessage).toHaveBeenLastCalledWith('Vent til forhåndsvisningen er klar.');
        jest.advanceTimersByTime(300);
        await flushPromises();
        expect(endDate.sendErrorMessage).toHaveBeenLastCalledWith('');
        expect(element.validateFields()).toBe(0);
    });

    it('blocks submission for an empty series and for a failed preview', async () => {
        previewRecurringWorkOrders.mockResolvedValueOnce({ ...preview, count: 0, intervals: [] });
        const element = await setup();
        jest.advanceTimersByTime(300);
        await flushPromises();
        expect(element.validateFields()).toBeGreaterThan(0);
        const endDate = element.shadowRoot.querySelector('[data-id="recurringEndDate"]');
        expect(endDate.sendErrorMessage).toHaveBeenLastCalledWith('Valgte gjentagelsesdager finnes ikke i perioden.');
        const log = jest.spyOn(console, 'error').mockImplementation(() => {});
        previewRecurringWorkOrders.mockRejectedValueOnce({ body: { message: 'Serverfeil' } });
        change(element, '[data-id="recurringEndDate"]', '2027-11-03');
        jest.advanceTimersByTime(300);
        await flushPromises();
        expect(element.validateFields()).toBeGreaterThan(0);
        expect(endDate.sendErrorMessage).toHaveBeenLastCalledWith('Serverfeil');
        log.mockRestore();
    });

    it('preserves both dates and the server-calculated overnight end time', async () => {
        previewRecurringWorkOrders.mockResolvedValue({
            ...preview,
            count: 1,
            intervals: [
                {
                    ...preview.intervals[0],
                    startLabel: '30.10.2027 23:00',
                    endLabel: '31.10.2027 02:00'
                }
            ]
        });
        const element = await setup();
        jest.advanceTimersByTime(300);
        await flushPromises();
        const cells = element.shadowRoot.querySelectorAll('tbody td');
        expect(cells[0].textContent).toBe('30.10.2027 23:00');
        expect(cells[1].textContent).toBe('31.10.2027 02:00');
    });

    it('refreshes after changing each timestamp, recurrence type and weekday selection', async () => {
        const element = await setup();
        jest.advanceTimersByTime(300);
        await flushPromises();
        for (const [selector, detail, eventName] of [
            ['[data-id="startTime"]', '02:30', 'getvalueonchange'],
            ['[data-id="endTime"]', '03:30', 'getvalueonchange'],
            ['[data-id="date"]', '2027-10-29', 'getvalueonchange'],
            ['[data-id="recurringType"]', { name: 'Biweekly' }, 'picklistvaluechange'],
            ['[data-id="recurringDays"]', [{ name: 'monday', checked: true }], 'checkboxgroupclick']
        ]) {
            change(element, selector, detail, eventName);
            await flushPromises();
            expect(element.shadowRoot.querySelector('details')).toBeNull();
            jest.advanceTimersByTime(300);
            await flushPromises();
            expect(element.shadowRoot.querySelector('details')).not.toBeNull();
        }
        expect(previewRecurringWorkOrders).toHaveBeenCalledTimes(6);
        expect(previewRecurringWorkOrders.mock.calls[5][0].recurringType).toBe('Biweekly');
        expect(previewRecurringWorkOrders.mock.calls[5][0].recurringDays).toEqual(['monday']);
    });
});
