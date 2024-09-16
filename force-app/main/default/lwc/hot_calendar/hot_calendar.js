import { LightningElement, track } from 'lwc';
import FULL_CALENDAR from '@salesforce/resourceUrl/FullCalendar';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import getUserServiceAppointments from '@salesforce/apex/HOT_FullCalendarController.getUserServiceAppointments';

export default class LibsFullCalendar extends LightningElement {
    isCalInitialized = false;
    error;
    calendar;
    @track events = []; //Brukt for å lagre data fra service appointments

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
            // Hent service appointments og initialisere kalender
            this.loadServiceAppointments();
        } catch (error) {
            console.error('Error loading FullCalendar or fetching service appointments:', error);
            this.error = error;
        }
    }

    loadServiceAppointments() {
        console.log('Calling Apex method getUserServiceAppointments...');
        getUserServiceAppointments()
            .then((result) => {
                console.log('Service appointments fetched successfully:', result);

                // Map result to FullCalendar events format
                this.events = result.map((event) => ({
                    title: event.title,
                    start: event.start,
                    duration: event.duration // Now you have the duration for each event
                }));

                console.log('Mapped events for FullCalendar:', this.events);
                this.initializeCalendar();
            })
            .catch((error) => {
                console.error('Error fetching service appointments from Apex:', error);
                this.error = error;
            });
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
            events: this.events
        });

        console.log('Rendrer FullCalendar med events:', this.events);
        this.calendar.render();
    }
}
