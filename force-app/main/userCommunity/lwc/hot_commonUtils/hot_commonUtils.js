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
