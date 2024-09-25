import { LightningElement, track, wire } from 'lwc';
import FULL_CALENDAR from '@salesforce/resourceUrl/FullCalendar';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import getCalendarEvents from '@salesforce/apex/HOT_FullCalendarController.getCalendarEvents';
import IKONER from '@salesforce/resourceUrl/ikoner';

export default class LibsFullCalendar extends LightningElement {
    static MILLISECONDS_PER_DAY = 86400000;
    static DAYS_TO_FETCH_FROM_TODAY = 4 * 31;
    static DAYS_TO_FETCH_BEFORE_TODAY = 2 * 31;
    static FETCH_THRESHOLD_IN_DAYS = 31; // How 'close' date view start or end can get to earliestTime or latestTime before a fetch of new events occurs
    static REFRESH_ICON = IKONER + '/Refresh/Refresh.svg';
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

    async refreshCalendar() {
        this.cachedEventIds.clear();
        this.todayInMilliseconds = new Date().getTime();
        this.earliestTime =
            this.todayInMilliseconds -
            LibsFullCalendar.DAYS_TO_FETCH_BEFORE_TODAY * LibsFullCalendar.MILLISECONDS_PER_DAY;
        this.latestTime =
            this.todayInMilliseconds +
            LibsFullCalendar.DAYS_TO_FETCH_FROM_TODAY * LibsFullCalendar.MILLISECONDS_PER_DAY;

        const events = await this.fetchUniqueEventsForTimeRegion(this.earliestTime, this.latestTime);
        this.events = events;

        this.calendar.removeAllEvents();

        for (const event of events) {
            this.calendar.addEvent(event);
        }
        console.log(`Calendar set up with ${this.events.length} events`);
    }

    async getCalendarConfig(events) {
        const screenWidth = window.innerWidth;
        let config = {
            datesSet: (dateInfo) => {
                this.updateEventsFromDateRange(dateInfo.start, dateInfo.end);
            },
            dayHeaderDidMount: (arg) => {
                const newNode = document.createElement('p');
                const oldNode = arg.el.childNodes[0].childNodes[0];
                newNode.textContent = oldNode.textContent;
                newNode.classList = oldNode.classList;
                arg.el.childNodes[0].replaceChild(newNode, oldNode);
            },
            navLinks: true,
            allDaySlot: false,
            navLinkDayClick: (date) => {
                this.calendar.changeView('timeGridDay', date);
            },
            firstDay: 1, // Mandag
            locale: 'nb',
            events: events,
            customButtons: {
                refresh: {
                    text: 'Refresh',
                    click: () => {
                        this.refreshCalendar(); // Call the refresh method
                    }
                }
            },
            buttonText: {
                today: 'I dag',
                month: 'Måned',
                week: 'Uke',
                day: 'Dag'
            },
            headerToolbar: {
                start: 'title',
                center: 'dayGridMonth',
                end: 'today prev,next'
            },
            footerToolbar: {
                left: 'refresh'
            },
            slotLabelFormat: {
                hour: '2-digit',
                minute: '2-digit'
            },
            dayMaxEventRows: 0,
            moreLinkClick: 'timeGrid',
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
                    fixedWeekCount: false,
                    dayMaxEventRows: 4
                }
            },
            viewDidMount: (info) => {
                const elements = document.getElementsByClassName('fc-refresh-button');
                if (elements.length > 0) {
                    const el = elements[0];
                    console.log('fant knappen');
                    el.innerHTML = `<img src="${LibsFullCalendar.REFRESH_ICON}" alt="Refresh Icon" style="width:16px; color:white; height:16px;" /> Oppdater tider`;
                }
            },
            eventClick: (info) => this.handleEventClick(info)
        };
        if (screenWidth < 500) {
            // Small screens (e.g., mobile)
            config.headerToolbar = {
                start: 'prev,next',
                center: 'title',
                end: 'today dayGridMonth'
            };
            config.titleFormat = { year: 'numeric', month: 'short' };
            config.views.dayGridMonth.dayMaxEventRows = 10;
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
    static RED_300 = '#F25C5C';
    static BLUE_200 = '#99C3FF';
    static GREEN_300 = '#66C786';
    static ORANGE_200 = '#FFD799';

    static eventTypeProperties = new Map([
        [
            'SERVICE_APPOINTMENT',
            {
                fontColor: 'black',
                color: CalendarEvent.BLUE_200,
                pastFontColor: 'white',
                pastColor: CalendarEvent.RED_300
            }
        ],
        ['COMPLETED_SERVICE_APPOINTMENT', { fontColor: 'black', color: CalendarEvent.GREEN_300 }],
        ['OPEN_WAGE_CLAIM', { fontColor: 'black', color: CalendarEvent.ORANGE_200 }]
    ]);

    recordId;
    type;
    title;
    start;
    end;
    isPast;
    color;
    eventTextColor;

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
        const properties = this.getEventProperties(eventType) ?? {
            upcomingColor: '#90cce8',
            pastColor: '#90cce8'
        };
        this.color = (this.isPast ? properties.pastColor : properties.color) ?? properties.color;
        this.eventTextColor = (this.isPast ? properties.pastFontColor : properties.fontColor) ?? properties.fontColor;
    }

    colorFromType(eventType) {}

    getEventProperties(eventType) {
        return CalendarEvent.eventTypeProperties.get(eventType);
    }
}
