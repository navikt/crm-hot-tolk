import { LightningElement, track, wire } from 'lwc';
import FULL_CALENDAR from '@salesforce/resourceUrl/FullCalendar';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import getCalendarEvents from '@salesforce/apex/HOT_FullCalendarController.getCalendarEvents';

export default class LibsFullCalendar extends LightningElement {
    isCalInitialized = false;
    error;
    calendar;
    @track events = []; //Brukt for å lagre data fra service appointments
    renderedCallback() {}

    async setupEvents() {
        //fetch events from service appointments
        const data = await getCalendarEvents();
        if (data) {
            this.events = data.map((event) => new CalendarEvent(event));
        } else {
            console.error('Error fetching service appointments from Apex:', error);
            this.error = error;
        }
        return this.events;
    }
    async setupCalendar() {
        await this.loadScriptAndStyle();
        const events = await this.setupEvents();
        await this.initializeCalendar(events);
    }

    async loadScriptAndStyle() {
        try {
            await Promise.all([
                loadScript(this, FULL_CALENDAR + '/main.min.js'),
                loadStyle(this, FULL_CALENDAR + '/main.min.css')
            ]);
        } catch (error) {
            console.error('Error loading FullCalendar or fetching service appointments:', error);
            this.error = error;
        }
    }
    connectedCallback() {
        this.setupCalendar();
    }

    async initializeCalendar(events) {
        const calendarEl = this.template.querySelector('.calendar');

        if (typeof FullCalendar === 'undefined') {
            throw new Error(
                'Could not load FullCalendar. Make sure that Lightning Web Security is enabled for your org.'
            );
        }

        const calendarConfig = await this.getCalendarConfig(events);

        this.calendar = new FullCalendar.Calendar(calendarEl, calendarConfig);
        this.calendar.render();
    }

    async getCalendarConfig(events) {
        const screenWidth = window.innerWidth;
        let config = {
            events: events,
            headerToolbar: {
                start: 'title',
                center: 'dayGridMonth',
                end: 'today prev,next'
            },
            dayMaxEventRows: 0,
            moreLinkClick: 'timeGrid',
            display: 'background',
            eventTimeFormat: {
                hour12: false,
                hour: '2-digit',
                minute: '2-digit'
            },
            views: {
                dayGrid: {
                    dayMaxEventRows: 10
                },
                timeGrid: {},
                week: {},
                day: {},
                dayGridMonth: {
                    dayMaxEventRows: 4
                }
            },
            eventClick: (info) => this.handleEventClick(info)
        };
        if (screenWidth < 768) {
            // Small screens (e.g., mobile)
            config.headerToolbar = {
                start: 'prev,next',
                center: 'title',
                end: 'today dayGridMonth'
            };
            config.views.dayGridMonth.dayMaxEventRows = 0;
        }

        return config;
    }

    handleEventClick(info) {
        // Handle event click logic, e.g., change view to timeGridDay
        this.calendar.changeView('timeGridDay', new Date(info.event.start));
        console.log('Event clicked:', info);
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
