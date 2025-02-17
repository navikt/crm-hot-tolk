export function formatDatetime(Start, DueDate) {
    // Parse the input dates
    const datetimeStart = new Date(Start);
    const datetimeEnd = new Date(DueDate);

    // Validate dates
    if (isNaN(datetimeStart) || isNaN(datetimeEnd)) {
        console.error('Invalid date conversion.');
        return null;
    }

    // Format options for Norwegian locale
    const optionsDate = { timeZone: 'Europe/Oslo', day: '2-digit', month: '2-digit', year: 'numeric' };
    const optionsTime = { timeZone: 'Europe/Oslo', hour: '2-digit', minute: '2-digit' };

    const formattedDate = new Intl.DateTimeFormat('nb-NO', optionsDate).format(datetimeStart);
    const formattedTimeStart = new Intl.DateTimeFormat('nb-NO', optionsTime).format(datetimeStart);
    const formattedTimeEnd = new Intl.DateTimeFormat('nb-NO', optionsTime).format(datetimeEnd);

    return `${formattedDate}, ${formattedTimeStart} - ${formattedTimeEnd}`;
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
