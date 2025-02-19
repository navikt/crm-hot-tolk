export class CalendarEvent {
    static RED_200 = '#F68282';
    static BLUE_200 = '#99C3FF';
    static GREEN_300 = '#66C786';
    static ORANGE_300 = '#FFC166';
    static PURPLE_400 = '#8269A2';

    static eventTypeProperties = new Map([
        [
            'SERVICE_APPOINTMENT',
            {
                fontColor: 'black',
                color: CalendarEvent.BLUE_200,
                pastFontColor: 'black',
                pastColor: CalendarEvent.RED_200
            }
        ],
        ['COMPLETED_SERVICE_APPOINTMENT', { fontColor: 'black', color: CalendarEvent.GREEN_300 }],
        ['OPEN_WAGE_CLAIM', { fontColor: 'black', color: CalendarEvent.ORANGE_300 }],
        ['RESOURCE_ABSENCE', { fontColor: 'white', color: CalendarEvent.PURPLE_400 }]
    ]);

    recordId;
    type;
    title;
    saNumber;
    description;
    start;
    end;
    isPast;
    isMultiDay;
    isPseudoEvent;
    color;
    textColor;

    constructor(data) {
        this.recordId = data.id;
        this.saNumber = data.appointmentNumber ?? '';
        this.description = data.description;
        this.title = this.saNumber;

        //Convert start & end to correct timezone in ISO format
        this.start = this.convertToOsloTime(data.startTime);
        this.end = this.convertToOsloTime(data.endTime);

        this.type = data.type;
        this.isPast = new Date(this.end) <= new Date();

        const properties = CalendarEvent.eventTypeProperties.get(this.type) ?? {
            upcomingColor: '#90cce8',
            pastColor: '#90cce8'
        };
        this.color = (this.isPast ? properties.pastColor : properties.color) ?? properties.color;
        this.textColor = (this.isPast ? properties.pastFontColor : properties.fontColor) ?? properties.fontColor;

        //Convert back to Date before checking `toLocaleDateString()`
        const startDate = new Date(this.start);
        const endDate = new Date(this.end);

        this.isMultiDay =
            startDate.toLocaleDateString('nb-NO') !== endDate.toLocaleDateString('nb-NO') && startDate < endDate;

        this.isPseudoEvent = false;
    }

    convertToOsloTime(isoString) {
        // Convert UTC time to Oslo time, keeping the Date object
        return new Date(new Date(isoString).toLocaleString('en-US', { timeZone: 'Europe/Oslo' })).toISOString();
    }
}
