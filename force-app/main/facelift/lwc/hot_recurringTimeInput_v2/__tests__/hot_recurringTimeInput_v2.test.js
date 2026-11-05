import { createElement } from 'lwc';
import RecurringTimeInput from 'c/hot_recurringTimeInput_v2';
import getTimes from '@salesforce/apex/HOT_RequestListController.getTimesNew';
import previewRecurringWorkOrders from '@salesforce/apex/HOT_CreateWorkOrderService.previewRecurringWorkOrders';
import { restrictTheNumberOfDays } from '../hot_recurringTimeInput_validationRules';

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
        jest.restoreAllMocks();
    });

    it('includes the visible delete label and interval context in each accessible name', async () => {
        const element = await setup();
        change(element, 'c-checkbox', false, 'checkboxclick');
        await flushPromises();
        const addButton = [...element.shadowRoot.querySelectorAll('c-button')].find(
            (button) => button.buttonLabel === '+ Legg til flere tider'
        );
        addButton.dispatchEvent(new CustomEvent('buttonclick'));
        await flushPromises();
        const deleteButtons = [...element.shadowRoot.querySelectorAll('.listClass c-button')];
        expect(deleteButtons.map((button) => button.buttonLabel)).toEqual(['Slett', 'Slett']);
        expect(deleteButtons[0].shadowRoot.querySelector('button').getAttribute('aria-label')).toBe(
            'Slett tidspunkt 1, dato 30.10.2027, starttid 00:30, sluttid 01:30'
        );
        expect(deleteButtons[1].shadowRoot.querySelector('button').getAttribute('aria-label')).toBe(
            'Slett tidspunkt 2'
        );

        const secondRow = element.shadowRoot.querySelectorAll('.listClass')[1];
        for (const [field, value] of [
            ['date', '2027-11-03'],
            ['startTime', '09:00'],
            ['endTime', '10:00']
        ]) {
            secondRow
                .querySelector(`[data-id="${field}"]`)
                .dispatchEvent(new CustomEvent('getvalueonchange', { detail: value }));
            await flushPromises();
        }
        const secondDeleteButton = element.shadowRoot.querySelectorAll('.listClass c-button')[1];
        expect(secondDeleteButton.shadowRoot.querySelector('button').getAttribute('aria-label')).toBe(
            'Slett tidspunkt 2, dato 03.11.2027, starttid 09:00, sluttid 10:00'
        );
        expect(secondDeleteButton.buttonLabel).toBe('Slett');
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
            'Datoene i serien er tilpasset ukedagene du har valgt.'
        );
        const previewContainer = element.shadowRoot.querySelector('.recurring-preview');
        expect(previewContainer.querySelector('h3').textContent).toBe('Forhåndsvisning av tidspunkter');
        expect(previewContainer.querySelector('[role="status"]').textContent).toBe('2 tidspunkter');
        expect([...previewContainer.querySelectorAll('dd')].map((cell) => cell.textContent)).toEqual([
            '31.10.2027',
            '01.11.2027'
        ]);
        expect(previewContainer.querySelector('.recurring-boundary-warning')).not.toBeNull();
        const details = previewContainer.querySelector('details');
        expect(details).not.toBeNull();
        expect(details.open).toBe(false);
        expect(details.querySelector('.recurring-preview-chevron').getAttribute('aria-hidden')).toBe('true');
        expect(details.querySelector('summary').textContent).toBe('Vis alle 2 tidspunkter');
        expect(previewContainer.textContent).not.toContain('Tidssone:');
        expect(previewContainer.lastElementChild.className).toBe('recurring-preview-hint');
        expect(previewContainer.lastElementChild.textContent).toBe(
            'Kontroller datoene og klokkeslettene før du sender inn.'
        );
        expect(details.querySelectorAll('tbody tr')).toHaveLength(2);
        expect([...details.querySelectorAll('thead th')].map((cell) => cell.textContent)).toEqual([
            'Dato',
            'Fra',
            'Til'
        ]);
        expect(
            [...details.querySelectorAll('tbody tr')[1].querySelectorAll('td')].map((cell) => cell.textContent)
        ).toEqual(['mandag 01.11.2027', '00:30', '01:30']);
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
        expect(element.shadowRoot.querySelector('.recurring-preview')).toBeNull();
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

    it.each([false, true])('blocks a series longer than 199 days in edit mode %s', async (editMode) => {
        const element = await setup(editMode);
        change(element, '[data-id="recurringType"]', { name: 'Every4Weeks' }, 'picklistvaluechange');
        change(element, '[data-id="recurringEndDate"]', '2035-11-02');
        jest.advanceTimersByTime(300);
        await flushPromises();
        expect(previewRecurringWorkOrders).not.toHaveBeenCalled();
        expect(element.validateFields()).toBeGreaterThan(0);
        expect(element.shadowRoot.querySelector('details')).toBeNull();
        expect(element.shadowRoot.querySelector('[role="alert"]').textContent).toBe(
            'Du kan ikke legge inn gjentagende bestilling med en varighet på over 6 måneder'
        );
    });

    it('blocks saving and displays the server interval-count limit for a long series', async () => {
        const log = jest.spyOn(console, 'error').mockImplementation(() => {});
        previewRecurringWorkOrders.mockRejectedValue({
            body: { message: 'Kan ikke opprette mer enn 200 arbeidsordre av gangen.' }
        });
        const element = await setup();
        jest.advanceTimersByTime(300);
        await flushPromises();
        expect(element.validateFields()).toBeGreaterThan(0);
        expect(element.shadowRoot.querySelector('[role="alert"]').textContent).toBe(
            'Kan ikke opprette mer enn 200 arbeidsordre av gangen.'
        );
        log.mockRestore();
    });

    it('allows exactly 199 days and rejects one millisecond beyond the legacy boundary', () => {
        const start = Date.parse('2027-10-30T09:00:00Z');
        const limit = start + 199 * 86400000;
        expect(restrictTheNumberOfDays(limit, start)).toBe('');
        expect(restrictTheNumberOfDays(limit + 1, start)).toBe(
            'Du kan ikke legge inn gjentagende bestilling med en varighet på over 6 måneder'
        );
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
            firstDate: '2027-10-30',
            lastDate: '2027-10-30',
            count: 1,
            intervals: [
                {
                    ...preview.intervals[0],
                    startTime: Date.parse('2027-10-30T21:00:00Z'),
                    endTime: Date.parse('2027-10-31T01:00:00Z'),
                    startLabel: '30.10.2027 23:00',
                    endLabel: '31.10.2027 02:00'
                }
            ]
        });
        const element = await setup();
        jest.advanceTimersByTime(300);
        await flushPromises();
        const cells = element.shadowRoot.querySelectorAll('tbody td');
        expect(cells[0].textContent).toBe('lørdag 30.10.2027');
        expect(cells[1].textContent).toBe('23:00');
        expect(cells[2].textContent).toBe('31.10.2027 02:00');
        expect(element.shadowRoot.querySelector('.recurring-preview-count').textContent).toBe('1 tidspunkt');
        expect(element.shadowRoot.querySelector('summary').textContent).toBe('Vis tidspunktet');
    });

    it('uses Norwegian time for weekdays when the UTC date is different', async () => {
        previewRecurringWorkOrders.mockResolvedValue({
            ...preview,
            timeZone: 'Europe/Oslo',
            firstDate: '2027-11-01',
            lastDate: '2027-11-01',
            count: 1,
            intervals: [
                {
                    startTime: Date.parse('2027-10-31T23:30:00Z'),
                    endTime: Date.parse('2027-11-01T00:30:00Z'),
                    startLabel: '01.11.2027 00:30',
                    endLabel: '01.11.2027 01:30'
                }
            ]
        });
        const element = await setup();
        jest.advanceTimersByTime(300);
        await flushPromises();
        expect(element.shadowRoot.querySelector('tbody td').textContent).toBe('mandag 01.11.2027');
    });

    it.each([
        ['Europe/Oslo', false],
        ['Europe/Paris', false],
        ['Europe/Berlin', false],
        ['UTC', true],
        ['America/New_York', true],
        ['Asia/Kolkata', true]
    ])('shows the Norwegian time notice only when browser time differs in %s', async (timeZone, showNotice) => {
        jest.spyOn(Intl.DateTimeFormat.prototype, 'resolvedOptions').mockReturnValue({ timeZone });
        previewRecurringWorkOrders.mockResolvedValue({ ...preview, timeZone: 'Europe/Oslo' });
        const element = await setup();
        jest.advanceTimersByTime(300);
        await flushPromises();
        const notice = element.shadowRoot.querySelector('.recurring-preview-timezone');
        expect(notice !== null).toBe(showNotice);
        expect(element.shadowRoot.querySelector('details').open).toBe(false);
        if (showNotice) {
            expect(notice.textContent).toBe('Alle datoer og klokkeslett i forhåndsvisningen er oppgitt i norsk tid.');
            expect(notice.closest('details')).toBeNull();
        }
    });

    it('checks both endpoints for time differences across a daylight-saving transition', async () => {
        jest.spyOn(Intl.DateTimeFormat.prototype, 'resolvedOptions').mockReturnValue({ timeZone: 'Africa/Tunis' });
        previewRecurringWorkOrders.mockResolvedValue({
            ...preview,
            timeZone: 'Europe/Oslo',
            firstDate: '2027-03-28',
            lastDate: '2027-03-28',
            count: 1,
            intervals: [
                {
                    startTime: Date.parse('2027-03-28T00:30:00Z'),
                    endTime: Date.parse('2027-03-28T01:30:00Z'),
                    startLabel: '28.03.2027 01:30',
                    endLabel: '28.03.2027 03:30'
                }
            ]
        });
        const element = await setup();
        jest.advanceTimersByTime(300);
        await flushPromises();
        expect(element.shadowRoot.querySelector('.recurring-preview-timezone')).not.toBeNull();
    });

    it('checks every interval rather than only the current time or first occurrence', async () => {
        jest.spyOn(Intl.DateTimeFormat.prototype, 'resolvedOptions').mockReturnValue({ timeZone: 'Africa/Tunis' });
        previewRecurringWorkOrders.mockResolvedValue({
            ...preview,
            timeZone: 'Europe/Oslo',
            firstDate: '2027-03-27',
            lastDate: '2027-03-28',
            intervals: [
                {
                    startTime: Date.parse('2027-03-27T10:00:00Z'),
                    endTime: Date.parse('2027-03-27T11:00:00Z'),
                    startLabel: '27.03.2027 11:00',
                    endLabel: '27.03.2027 12:00'
                },
                {
                    startTime: Date.parse('2027-03-28T09:00:00Z'),
                    endTime: Date.parse('2027-03-28T10:00:00Z'),
                    startLabel: '28.03.2027 11:00',
                    endLabel: '28.03.2027 12:00'
                }
            ]
        });
        const element = await setup();
        jest.advanceTimersByTime(300);
        await flushPromises();
        expect(element.shadowRoot.querySelector('.recurring-preview-timezone')).not.toBeNull();
    });

    it('keeps the date summary without a boundary explanation when selected boundaries match', async () => {
        previewRecurringWorkOrders.mockResolvedValue({
            ...preview,
            firstDate: '2027-10-30',
            lastDate: '2027-11-02'
        });
        const element = await setup();
        jest.advanceTimersByTime(300);
        await flushPromises();
        expect(element.shadowRoot.querySelector('.recurring-boundary-warning')).toBeNull();
        expect(
            [...element.shadowRoot.querySelectorAll('.recurring-preview-dates dd')].map((cell) => cell.textContent)
        ).toEqual(['30.10.2027', '02.11.2027']);
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
