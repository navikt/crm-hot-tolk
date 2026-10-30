import getRecurringDateRange from '../recurringDateRange';

describe('getRecurringDateRange', () => {
    it('returns actual first and last dates when selected weekdays shift the requested range', () => {
        expect(getRecurringDateRange('2026-10-27', '2026-11-01', 'Weekly', ['wednesday'])).toEqual({
            firstDate: '2026-10-28',
            lastDate: '2026-10-28'
        });
    });

    it('applies the same week skipping as Apex for biweekly and four-week recurrences', () => {
        expect(getRecurringDateRange('2026-10-26', '2026-11-23', 'Biweekly', ['monday'])).toEqual({
            firstDate: '2026-10-26',
            lastDate: '2026-11-23'
        });
        expect(getRecurringDateRange('2026-10-26', '2026-11-23', 'Every4Weeks', ['monday'])).toEqual({
            firstDate: '2026-10-26',
            lastDate: '2026-11-23'
        });
    });

    it('returns no dates when selected days do not occur in the range', () => {
        expect(getRecurringDateRange('2026-10-27', '2026-10-27', 'Weekly', ['monday'])).toEqual({
            firstDate: null,
            lastDate: null
        });
    });
});
