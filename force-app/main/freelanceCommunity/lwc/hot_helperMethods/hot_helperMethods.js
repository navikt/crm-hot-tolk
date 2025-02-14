export function formatDatetime(Start, DueDate) {
    const datetimeStart = new Date(new Date(Start).toLocaleString('nb-NO', { timeZone: 'Europe/Oslo' }));
    const datetimeEnd = new Date(new Date(DueDate).toLocaleString('nb-NO', { timeZone: 'Europe/Oslo' }));

    // Check for invalid Date objects
    if (isNaN(datetimeStart) || isNaN(datetimeEnd)) {
        console.error('Invalid date conversion.');
        return null; // or handle the error as needed
    }
    const dayStart = datetimeStart.getDate().toString();
    const monthStart = (datetimeStart.getMonth() + 1).toString();
    const yearStart = datetimeStart.getFullYear();
    const hoursStart = datetimeStart.getHours().toString().padStart(2, '0');
    const minutesStart = datetimeStart.getMinutes().toString().padStart(2, '0');

    const hoursEnd = datetimeEnd.getHours().toString().padStart(2, '0');
    const minutesEnd = datetimeEnd.getMinutes().toString().padStart(2, '0');

    const formattedDatetime = `${dayStart}.${monthStart}.${yearStart}, ${hoursStart}:${minutesStart} - ${hoursEnd}:${minutesEnd}`;
    return formattedDatetime;
}
export function getDayOfWeek(date) {
    var jsDate = new Date(date);
    var dayOfWeek = jsDate.getDay();
    var dayOfWeekString;
    switch (dayOfWeek) {
        case 0:
            dayOfWeekString = 'Søndag';
            break;
        case 1:
            dayOfWeekString = 'Mandag';
            break;
        case 2:
            dayOfWeekString = 'Tirsdag';
            break;
        case 3:
            dayOfWeekString = 'Onsdag';
            break;
        case 4:
            dayOfWeekString = 'Torsdag';
            break;
        case 5:
            dayOfWeekString = 'Fredag';
            break;
        case 6:
            dayOfWeekString = 'Lørdag';
            break;
        default:
            dayOfWeekString = '';
    }
    return dayOfWeekString;
}
// export function convertToOsloTime(startTime, endTime) {
//     const osloStartString = startTime.toLocaleString('nb-NO', { timeZone: 'Europe/Oslo' });
//     const osloEndString = endTime.toLocaleString('nb-NO', { timeZone: 'Europe/Oslo' });

//     // Create new Date objects for start and end time after conversion
//     const osloStart = new Date(osloStartString);
//     const osloEnd = new Date(osloEndString);

//     const startDate = osloStart.getDate() + '.' + (osloStart.getMonth() + 1) + '.' + osloStart.getFullYear();
//     const startTimeString = osloStart.getHours() + ':' + osloStart.getMinutes();

//     const endTimeString = osloEnd.getHours() + ':' + osloEnd.getMinutes();

//     return `${startDate}, ${startTimeString} - ${endTimeString}`;
// }
