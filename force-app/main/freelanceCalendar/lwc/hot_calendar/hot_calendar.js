import { LightningElement, track, wire } from 'lwc';
import FULL_CALENDAR from '@salesforce/resourceUrl/FullCalendar';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import getCalendarEvents from '@salesforce/apex/HOT_FullCalendarController.getCalendarEvents';

export default class LibsFullCalendar extends LightningElement {
    static MILLISECONDS_PER_DAY = 86400000;
    static DAYS_TO_FETCH_FROM_TODAY = 4 * 31;
    static DAYS_TO_FETCH_BEFORE_TODAY = 2 * 31;
    static FETCH_THRESHOLD_IN_DAYS = 31; // How 'close' date view start or end can get to earliestTime or latestTime before a fetch of new events occurs
    todayInMilliseconds;
    earliestTime;
    latestTime;
    cachedEventIds = new Set();
    isCalInitialized = false;
    error;
    calendar;
    @track events = []; //Brukt for å lagre data fra service appointments
    renderedCallback() {}

    async setupCalendar() {
        await this.loadScriptAndStyle();
        const events = await this.fetchUniqueEventsForTimeRegion(this.earliestTime, this.latestTime);
        this.events = events;
        console.log(`Calendar set up with ${this.events.length} initial events`);
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
        this.todayInMilliseconds = new Date().getTime();
        this.earliestTime =
            this.todayInMilliseconds -
            LibsFullCalendar.DAYS_TO_FETCH_BEFORE_TODAY * LibsFullCalendar.MILLISECONDS_PER_DAY;
        this.latestTime =
            this.todayInMilliseconds +
            LibsFullCalendar.DAYS_TO_FETCH_FROM_TODAY * LibsFullCalendar.MILLISECONDS_PER_DAY;
        this.setupCalendar();
    }

    async fetchUniqueEventsForTimeRegion(earliestTime, latestTime) {
        const data = await getCalendarEvents({
            earliestEventEndTimeInMilliseconds: earliestTime,
            latestEventStartInMilliseconds: latestTime
        });
        if (data) {
            return data
                .map((event) => new CalendarEvent(event))
                .filter((event) => {
                    const isAlreadyCached = this.cachedEventIds.has(event.recordId);
                    if (!isAlreadyCached) {
                        this.cachedEventIds.add(event.recordId);
                    }
                    return !isAlreadyCached;
                });
        } else {
            console.error('Error fetching service appointments from Apex:', error);
            this.error = error;
            return [];
        }
    }

    async updateEventsFromDateRange(earliestDateInView, latestDateInView) {
        const earliestTimeInView = earliestDateInView.getTime();
        const latestTimeInView = latestDateInView.getTime();
        const events = [];

        const fetchThresholdInMilliseconds =
            LibsFullCalendar.FETCH_THRESHOLD_IN_DAYS * LibsFullCalendar.MILLISECONDS_PER_DAY;

        if (earliestTimeInView < this.earliestTime + fetchThresholdInMilliseconds) {
            const newEarliestTime =
                this.earliestTime - LibsFullCalendar.DAYS_TO_FETCH_BEFORE_TODAY * LibsFullCalendar.MILLISECONDS_PER_DAY;
            const pastEvents = await this.fetchUniqueEventsForTimeRegion(newEarliestTime, this.earliestTime);
            this.earliestTime = newEarliestTime;
            events.push(...pastEvents);
        }

        if (latestTimeInView > this.latestTime - fetchThresholdInMilliseconds) {
            const newLatestTime =
                this.latestTime + LibsFullCalendar.DAYS_TO_FETCH_FROM_TODAY * LibsFullCalendar.MILLISECONDS_PER_DAY;
            const futureEvents = await this.fetchUniqueEventsForTimeRegion(this.latestTime, newLatestTime);
            this.latestTime = newLatestTime;
            events.push(...futureEvents);
        }

        this.events.push(...events);
        for (const event of events) {
            this.calendar?.addEvent(event);
        }
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
            datesSet: (dateInfo) => {
                this.updateEventsFromDateRange(dateInfo.start, dateInfo.end);
            },
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

    recordId;
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
        this.recordId = data.id;
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
