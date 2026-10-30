/**
 * Returns first and last occurrence dates using the recurrence rules used by Apex.
 */
export default function getRecurringDateRange(startDate, endDate, recurringType, selectedDays = []) {
    if (!startDate || !endDate) {
        return { firstDate: null, lastDate: null };
    }

    const [startYear, startMonth, startDay] = startDate.split('-').map(Number);
    const [endYear, endMonth, endDay] = endDate.split('-').map(Number);
    const startUtc = Date.UTC(startYear, startMonth - 1, startDay);
    const endUtc = Date.UTC(endYear, endMonth - 1, endDay);
    const numberOfDays = Math.floor((endUtc - startUtc) / 86400000);
    if (numberOfDays < 0) {
        return { firstDate: null, lastDate: null };
    }

    const dayNames = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
    let firstDate = null;
    let lastDate = null;

    for (let offset = 0; offset <= numberOfDays; offset++) {
        const occurrenceDate = new Date(startUtc + offset * 86400000);
        const dayName = dayNames[occurrenceDate.getUTCDay()];

        if (recurringType === 'Daily' || selectedDays.includes(dayName)) {
            const formattedDate = occurrenceDate.toISOString().slice(0, 10);
            firstDate = firstDate || formattedDate;
            lastDate = formattedDate;
        }

        if (recurringType === 'Biweekly' && dayName === 'sunday') {
            offset += 7;
        } else if (recurringType === 'Every4Weeks' && dayName === 'sunday') {
            offset += 21;
        }
    }

    return { firstDate, lastDate };
}
