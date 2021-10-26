import { require } from 'c/validationController';

export let startDateValidations = [require, dateInPast];
export let startTimeValidations = [require];
export let endTimeValidations = [require, startBeforeEnd];
export let recurringTypeValidations = [require];
export let recurringDaysValidations = [requireDaysBasedOnRecurringType];
export let recurringEndDateValidations = [
    require,
    startDateBeforeRecurringEndDate,
    restrictTheNumberOfDays,
    chosenDaysWithinPeriod
];

let nowDate = new Date();

function dateInPast(date) {
    if (date == null || date == '') {
        return '';
    }
    date = new Date(date);
    let today = new Date(nowDate.getFullYear(), nowDate.getMonth(), nowDate.getDate(), 0, 0, 0, 0);
    return date.getTime() < today.getTime() ? 'Du kan ikke bestille tid i fortiden' : '';
}

function startBeforeEnd(endDate, args) {
    return '';
    let startDate = new Date(args[0]);
    endDate = new Date(endDate);
    return startDate.getTime() > endDate.getTime() ? 'Start tid må være før slutt tid.' : '';
}

function requireDaysBasedOnRecurringType(days, ...args) {
    let type = args[0];
    if ((type === 'Weekly' || type === 'Biweekly') && days.length === 0) {
        return 'Du må velge minst én dag tolkebehovet gjentas.';
    }
    return '';
}

function startDateBeforeRecurringEndDate(recurringEndDate, args) {
    let startDate = args[1];
    return new Date(startDate).getTime() > new Date(recurringEndDate) ? 'Slutt dato må være etter start dato' : '';
}
function restrictTheNumberOfDays(recurringEndDate, args) {
    let startDate = args[1];
    return new Date(recurringEndDate) - new Date(startDate).getTime() > 199 * 24 * 3600000 && startDate != null
        ? 'Du kan ikke legge inn gjentagende bestilling med en varighet på over 6 måneder'
        : '';
}
function chosenDaysWithinPeriod(recurringEndDate, args) {
    let type = args[0];
    if (type === 'Daily') {
        return '';
    }

    let startDate = args[1];
    startDate = new Date(startDate);
    recurringEndDate = new Date(recurringEndDate);
    if (recurringEndDate - startDate.getTime() < 7 * 24 * 3600000) {
        let days = args[2];
        let daysMap = { sunday: 0, monday: 1, tuesday: 2, wednesday: 3, thursday: 4, friday: 5, saturday: 6 };
        for (let day of days) {
            if (startDate.getDay() <= recurringEndDate.getDay()) {
                if (daysMap[day] >= startDate.getDay() && daysMap[day] <= recurringEndDate.getDay()) {
                    return '';
                }
            } else {
                if (daysMap[day] >= startDate.getDay() || daysMap[day] <= recurringEndDate.getDay()) {
                    return '';
                }
            }
        }
        return 'Velg en slutt dato slik at valgt dag faller innenfor perioden mellom start dato og slutt dato';
    }
    return '';
}
