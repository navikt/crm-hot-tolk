import { LightningElement, track, wire } from 'lwc';
import FULL_CALENDAR from '@salesforce/resourceUrl/FullCalendar';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import getCalendarEvents from '@salesforce/apex/HOT_FullCalendarController.getCalendarEvents';

export default class LibsFullCalendar extends LightningElement {
    isCalInitialized = false;
    error;
    calendar;
    @track events = []; //Brukt for å lagre data fra service appointments

    @wire(getCalendarEvents)
    wiredEvents({ error, data }) {
        if (data) {
            console.log('Service appointments fetched successfully:', data);

            this.events = data.map((event) => new CalendarEvent(event));
            console.log('Mapped events for FullCalendar:', this.events);
            this.initializeCalendar();
        } else if (error) {
            console.error('Error fetching service appointments from Apex:', error);
            this.error = error;
        }
    }

    async renderedCallback() {
        if (this.isCalInitialized) {
            return;
        }
        this.isCalInitialized = true;

        try {
            console.log('Loading FullCalendar scripts and styles...');
            await Promise.all([
                loadScript(this, FULL_CALENDAR + '/main.min.js'),
                loadStyle(this, FULL_CALENDAR + '/main.min.css')
            ]);

            console.log('FullCalendar scripts and styles loaded. Fetching service appointments...');
        } catch (error) {
            console.error('Error loading FullCalendar or fetching service appointments:', error);
            this.error = error;
        }
    }

    initializeCalendar() {
        console.log('initialiserer FullCalendar...');
        const calendarEl = this.template.querySelector('.calendar');

        if (typeof FullCalendar === 'undefined') {
            throw new Error(
                'Could not load FullCalendar. Make sure that Lightning Web Security is enabled for your org.'
            );
        }
        // Initialiserer kalender
        this.calendar = new FullCalendar.Calendar(calendarEl, {
            events: this.events,
            headerToolbar: {
                start: 'title', // will normally be on the left. if RTL, will be on the right
                center: 'dayGridMonth', // will normally be on the bottom. if RTL, will be on the top
                end: 'today prev,next' // will normally be on the right. if RTL, will be on the left
            },
            display: 'background',
            hour: '2-digit',
            minute: '2-digit',
            hour12: false,
            views: {
                dayGrid: {
                    // options apply to dayGridMonth, dayGridWeek, and dayGridDay views
                },
                timeGrid: {
                    // options apply to timeGridWeek and timeGridDay views
                },
                week: {
                    // options apply to dayGridWeek and timeGridWeek views
                },
                day: {
                    // options apply to dayGridDay and timeGridDay views
                }
            },
            eventClick: (info) => {
                this.calendar.changeView('timeGridDay', new Date(info.event.start));
                console.log('Trykk');
                console.log(info);
                console.log(info.event.start);
            }
        });

        console.log('Rendrer FullCalendar med events:', this.events);
        this.calendar.render();
    }
}

class CalendarEvent {
    static eventTypeProperties = new Map([
        ['SERVICE_APPOINTMENT', { upcomingColor: '#90cce8', pastColor: '#ff9a4d' }],
        ['COMPLETED_SERVICE_APPOINTMENT', { upcomingColor: '#90cce8', pastColor: '#90cce8' }],
        ['OPEN_WAGE_CLAIM', { upcomingColor: '#57ff6c', pastColor: '#b8a798' }]
    ]);

    id;
    type;
    title;
    start;
    end;
    isPast;
    color;

    /**
     *
     * @param {*} data - Forventer data i form av fra HOT_FullCalendarController.CalendarEvent
     */
    constructor(data) {
        this.id = data.id;
        this.title = data.title;
        this.start = new Date(data.startTime);
        this.end = new Date(data.endTime);
        this.type = data.type;
        this.isPast = this.end <= new Date();
        this.color = this.colorFromType(data.type);
    }

    colorFromType(eventType) {
        const properties = this.getEventProperties(eventType) ?? {
            upcomingColor: '#90cce8',
            pastColor: '#90cce8'
        };
        return this.isPast ? properties.pastColor : properties.upcomingColor;
    }

    getEventProperties(eventType) {
        return CalendarEvent.eventTypeProperties.get(eventType);
    }
}
