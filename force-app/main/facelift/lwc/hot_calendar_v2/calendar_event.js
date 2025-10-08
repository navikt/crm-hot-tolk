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

    /**
     *
     * @param {*} data - Forventer data i form av fra HOT_FullCalendarController.CalendarEvent
     */
    constructor(data) {
        this.recordId = data.id;
        this.saNumber = data.appointmentNumber ?? '';
        this.description = data.description;
        this.title = this.saNumber;
        this.start = new Date(data.startTime);
        this.end = new Date(data.endTime);
        this.type = data.type;
        this.isPast = this.end <= new Date();
        const properties = CalendarEvent.eventTypeProperties.get(this.type) ?? {
            upcomingColor: '#90cce8',
            pastColor: '#90cce8'
        };
        this.color = (this.isPast ? properties.pastColor : properties.color) ?? properties.color;
        this.textColor = (this.isPast ? properties.pastFontColor : properties.fontColor) ?? properties.fontColor;

        this.isMultiDay =
            this.start.toLocaleDateString('nb-NO') != this.end.toLocaleDateString('nb-NO') && this.start < this.end;
        this.isPseudoEvent = false;
    }
}
