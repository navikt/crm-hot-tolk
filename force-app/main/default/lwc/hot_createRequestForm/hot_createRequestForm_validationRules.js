import { require } from 'c/validationController';

export let startDateValidations = [dateInPast, require];
export let endDateValidations = [startBeforeEnd, require];
export let recurringTypeValidations = [require];
export let recurringDaysValidations = [requireDaysBasedOnRecurringType];
export let recurringEndDateValidations = [
    startDateBeforeRecurringEndDate,
    requireEndDateBasedOnRecurringType,
    restrictTheNumberOfDays
];

function dateInPast(date) {
    return new Date(date).getTime() < new Date().now() ? 'Du kan ikke bestille tid i fortiden' : '';
}
function startBeforeEnd(endDate, args) {
    let startDate = args[0];
    return new Date(startDate).getTime() < new Date(endDate) ? 'Start tid må være før slutt tid.' : '';
}

function requireDaysBasedOnRecurringType(days, ...args) {
    let type = args[0];
    if ((type === 'Weekly' || type === 'Biweekly') && days.length === 0) {
        return 'Du må velge minst én dag tolkebehovet gjentas.';
    }
    return '';
}

function startDateBeforeRecurringEndDate(recurringEndDate, args) {
    let startDate = args[0];
    return new Date(startDate).getTime() > new Date(recurringEndDate)
        ? 'Slutt dato for gjentakende tolkebehov må være før start tid'
        : '';
}
function requireEndDateBasedOnRecurringType(recurringEndDate, args) {
    let type = args[0];
    if (type !== 'Never' && (recurringEndDate === '' || recurringEndDate == null)) {
        return 'Fyll ut dette feltet.';
    }
    return '';
}
function restrictTheNumberOfDays(recurringEndDate, args) {
    let startDate = args[0];
    return new Date(recurringEndDate) - new Date(startDate).getTime() > (365 / 2) * 24 * 3600000
        ? 'Du kan ikke legge inn gjentagende bestilling med en varighet på over 6 måneder'
        : '';
}
