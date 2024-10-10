import { LightningElement, track, wire, api } from 'lwc';
import FULL_CALENDAR from '@salesforce/resourceUrl/FullCalendar';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import getCalendarEvents from '@salesforce/apex/HOT_FullCalendarController.getCalendarEvents';
import IKONER from '@salesforce/resourceUrl/ikoner';
import { NavigationMixin } from 'lightning/navigation';
import { CalendarEvent } from './calendar_event';
import Hot_Calendar_Absence_Modal from 'c/hot_calendar_absence_modal';

export default class LibsFullCalendar extends NavigationMixin(LightningElement) {
    static MILLISECONDS_PER_DAY = 86400000;
    static DAYS_TO_FETCH_FROM_TODAY = 4 * 31;
    static DAYS_TO_FETCH_BEFORE_TODAY = 2 * 31;
    static FETCH_THRESHOLD_IN_DAYS = 31; // How 'close' date view start or end can get to earliestTime or latestTime before a fetch of new events occurs
    static REFRESH_ICON = IKONER + '/Refresh/Refresh.svg';
    static MOBILE_BREAK_POINT = 500;
    static STATE_KEY = 'i98u14ij24j2+49i+04oasfdh';

    @track showDetails = false;
    isLoading = false;
    isMobileSize = false;
    earliestTime;
    latestTime;
    cachedEventIds = new Set();
    error;
    calendar;

    connectedCallback() {
        const state = sessionStorage.getItem(LibsFullCalendar.STATE_KEY);

        const loadedSessionState = state ? JSON.parse(state) : null;

        this.isMobileSize = window.innerWidth < LibsFullCalendar.MOBILE_BREAK_POINT;

        const viewDateInMilliseconds = state ? new Date(loadedSessionState.viewDate).getTime() : new Date().getTime();
        this.earliestTime =
            viewDateInMilliseconds -
            LibsFullCalendar.DAYS_TO_FETCH_BEFORE_TODAY * LibsFullCalendar.MILLISECONDS_PER_DAY;
        this.latestTime =
            viewDateInMilliseconds + LibsFullCalendar.DAYS_TO_FETCH_FROM_TODAY * LibsFullCalendar.MILLISECONDS_PER_DAY;

        this.setupCalendar(loadedSessionState).then(() => {
            this.updatePseudoEventsDisplay(this.calendar.view);
        });
    }

    disconnectedCallback() {
        const state = {
            viewDate: this.calendar?.getDate(),
            viewType: this.calendar?.view.type
        };
        sessionStorage.setItem(LibsFullCalendar.STATE_KEY, JSON.stringify(state));
    }

    async setupCalendar(sessionState) {
        await this.loadScriptAndStyle();
        const events = await this.fetchUniqueEventsForTimeRegion(this.earliestTime, this.latestTime);
        await this.initializeCalendar(events, sessionState);
    }

    async loadScriptAndStyle() {
        try {
            await Promise.all([
                loadScript(this, FULL_CALENDAR + '/main.min.js'),
                loadStyle(this, FULL_CALENDAR + '/main.min.css')
            ]);
        } catch (error) {
            this.error = error;
        }
    }

    async initializeCalendar(events, sessionState) {
        const calendarEl = this.template.querySelector('.calendar');

        if (typeof FullCalendar === 'undefined') {
            throw new Error(
                'Could not load FullCalendar. Make sure that Lightning Web Security is enabled for your org.'
            );
        }

        const calendarConfig = await this.getCalendarConfig(events, sessionState);

        this.calendar = new FullCalendar.Calendar(calendarEl, calendarConfig);
        this.calendar.render();
    }

    async getCalendarConfig(events, sessionState) {
        let config = {
            eventDidMount: (context) => {
                this.onEventMount(context);
            },
            windowResize: (context) => {
                this.isMobileSize = window.innerWidth < LibsFullCalendar.MOBILE_BREAK_POINT;
                this.updatePseudoEventsDisplay(context.view);
            },
            datesSet: (dateInfo) => {
                this.updateEventsFromDateRange(dateInfo.start, dateInfo.end).then(() => {
                    this.updatePseudoEventsDisplay(dateInfo.view);
                });
            },
            dayHeaderDidMount: (context) => {
                this.onDayHeaderMount(context);
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
                    text: '',
                    click: () => {
                        this.refreshCalendar(); // Call the refresh method
                    }
                },
                absence: {
                    text: 'Nytt fravær',
                    click: () => {
                        this.openAbsenceModal();
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
                end: 'dayGridMonth today prev,next'
            },
            footerToolbar: {
                left: 'refresh',
                right: 'absence'
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
            viewDidMount: (context) => {
                this.onViewMount(context.view);
            },
            eventClick: (info) => this.handleEventClick(info)
        };

        if (this.isMobileSize) {
            config.headerToolbar = {
                start: 'today dayGridMonth',
                center: 'title',
                end: 'prev,next'
            };
            config.titleFormat = { year: 'numeric', month: 'short' };
            config.views.dayGridMonth.dayMaxEventRows = 10;
        }

        if (sessionState) {
            config.initialDate = new Date(sessionState.viewDate);
            config.initialView = sessionState.viewType;
        }

        return config;
    }

    onEventMount(context) {
        if (context.view.type === 'timeGridDay') {
            //setTimeout er for å fikse rendering av event info i dayview, var en slags race condition
            setTimeout(() => {
                const titleElement = context.el.querySelector('.fc-event-title');
                if (titleElement) {
                    titleElement.textContent = '';
                    titleElement.textContent = `${context.event.title} - ${context.event.extendedProps.description}`;
                }
            }, 0);
        }
    }

    onDayHeaderMount(context) {
        const newNode = document.createElement('p');
        const oldNode = context.el.childNodes[0].childNodes[0];
        if (context.view.type === 'timeGridDay') {
            newNode.textContent = oldNode.textContent + ` ${this.calendar?.getDate().getDate()}.`;
        } else {
            newNode.textContent = oldNode.textContent;
        }
        newNode.classList = oldNode.classList;
        context.el.childNodes[0].replaceChild(newNode, oldNode);
    }

    onViewMount() {
        const elements = document.getElementsByClassName('fc-refresh-button');
        if (elements.length > 0) {
            const el = elements[0];
            el.innerHTML = `<img src="${LibsFullCalendar.REFRESH_ICON}" alt="Refresh Icon" style="width:16px; color:white; height:16px;" />`;
        }
    }

    async updatePseudoEventsDisplay(view) {
        this.calendar?.batchRendering(() => {
            this.calendar?.getEvents().forEach((event) => {
                if (!event.extendedProps.isMultiDay && !event.extendedProps.isPseudoEvent) {
                    return;
                } else if (event.extendedProps.isPseudoEvent) {
                    // Has to hide a pseuo event if it is on the first day of the current view due to a conflict with
                    // an event injected by fullcalendar
                    const shouldHideFirstPseudoEventOfMonth =
                        event.start.getDate() == view.activeStart.getDate() &&
                        event.start.getMonth() != view.currentStart.getMonth();
                    if (view.type === 'timeGridDay') {
                        if (event.display != 'none') {
                            event.setProp('display', 'none');
                        }
                    } else {
                        event.setProp(
                            'display',
                            this.isMobileSize && !shouldHideFirstPseudoEventOfMonth ? 'list-item' : 'none'
                        );
                    }
                } else {
                    event.setProp('display', this.isMobileSize ? 'list-item' : 'auto');
                }
            });
        });
    }

    handleEventClick(context) {
        if (context.view.type === 'timeGridDay' || !this.isMobileSize) {
            this.navigateToDetailView(context.event);
        } else {
            this.calendar.changeView('timeGridDay', new Date(context.event.start));
        }
    }

    async refreshCalendar(shouldSpin = true) {
        this.isLoading = true && shouldSpin;
        const minLoadingTime = new Promise((resolve) => setTimeout(resolve, 2500));

        this.cachedEventIds.clear();

        const viewDateInMilliseconds = this.calendar.getDate().getTime();
        this.earliestTime =
            viewDateInMilliseconds -
            LibsFullCalendar.DAYS_TO_FETCH_BEFORE_TODAY * LibsFullCalendar.MILLISECONDS_PER_DAY;
        this.latestTime =
            viewDateInMilliseconds + LibsFullCalendar.DAYS_TO_FETCH_FROM_TODAY * LibsFullCalendar.MILLISECONDS_PER_DAY;

        const events = await this.fetchUniqueEventsForTimeRegion(this.earliestTime, this.latestTime);

        this.calendar.removeAllEvents();

        for (const event of events) {
            this.calendar.addEvent(event);
        }

        if (shouldSpin) {
            await minLoadingTime;
        }
        this.isLoading = false;
    }

    async openAbsenceModal(event) {
        const result = await Hot_Calendar_Absence_Modal.open({ event: event });
        if (result) {
            this.refreshCalendar(false);
            this.updatePseudoEventsDisplay(this.calendar.view);
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
                earliestTimeInView -
                LibsFullCalendar.DAYS_TO_FETCH_BEFORE_TODAY * LibsFullCalendar.MILLISECONDS_PER_DAY;
            const pastEvents = await this.fetchUniqueEventsForTimeRegion(newEarliestTime, this.earliestTime);
            this.earliestTime = newEarliestTime;
            events.push(...pastEvents);
        }

        if (latestTimeInView > this.latestTime - fetchThresholdInMilliseconds) {
            const newLatestTime =
                latestTimeInView + LibsFullCalendar.DAYS_TO_FETCH_FROM_TODAY * LibsFullCalendar.MILLISECONDS_PER_DAY;
            const futureEvents = await this.fetchUniqueEventsForTimeRegion(this.latestTime, newLatestTime);
            this.latestTime = newLatestTime;
            events.push(...futureEvents);
        }

        for (const event of events) {
            this.calendar?.addEvent(event);
        }
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
                })
                .flatMap((event) => {
                    if (event.isMultiDay) {
                        return this.createPseudoEventsFromApexEvent(event);
                    } else {
                        return event;
                    }
                });
        } else {
            console.error('Error fetching service appointments from Apex:', error);
            this.error = error;
            return [];
        }
    }

    createPseudoEventsFromApexEvent(event) {
        const pseudoEvents = [];
        if (this.isMobileSize) {
            event.display = 'list-item';
        }
        pseudoEvents.push(event);
        const view = this.calendar?.view;

        var start = new Date(event.start.getTime() + LibsFullCalendar.MILLISECONDS_PER_DAY);
        const end = new Date(event.end.getTime() + LibsFullCalendar.MILLISECONDS_PER_DAY);

        while (start.toLocaleDateString('nb-NO') != end.toLocaleDateString('nb-NO')) {
            const pseudoEvent = JSON.parse(JSON.stringify(event));
            pseudoEvent.isPseudoEvent = true;
            pseudoEvent.start = new Date(start);
            pseudoEvent.end = new Date(start);
            const shouldHidePseudoEvent =
                !this.isMobileSize ||
                (view && view.type === 'timeGridDay') ||
                (view &&
                    pseudoEvent.start.getDate() == view.activeStart.getDate() &&
                    pseudoEvent.start.getMonth() != view.currentStart.getMonth());
            pseudoEvent.display = shouldHidePseudoEvent ? 'none' : 'list-item';
            pseudoEvents.push(pseudoEvent);
            start = new Date(start.getTime() + LibsFullCalendar.MILLISECONDS_PER_DAY);
        }
        return pseudoEvents;
    }

    async navigateToDetailView(event) {
        const eventExtendedProps = event.extendedProps;
        switch (eventExtendedProps.type) {
            case 'COMPLETED_SERVICE_APPOINTMENT':
                this.showDetails = true;
                this.template
                    .querySelector('c-hot_information-modal')
                    .goToRecordDetailsSAFromId(eventExtendedProps.recordId);
                break;
            case 'SERVICE_APPOINTMENT':
                this.showDetails = true;
                this.template
                    .querySelector('c-hot_information-modal')
                    .goToRecordDetailsSAFromId(eventExtendedProps.recordId);
                break;
            case 'OPEN_WAGE_CLAIM':
                this.showDetails = true;
                this.template
                    .querySelector('c-hot_information-modal')
                    .goToRecordDetailsWCFromId(eventExtendedProps.recordId);
                break;
            case 'RESOURCE_ABSENCE':
                const modal = await this.openAbsenceModal(event);
                console.log(modal);
                break;
        }
    }
    handleRefreshRecords() {
        this.refreshCalendar(false);
    }
}
