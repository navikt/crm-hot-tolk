import { LightningElement, api } from 'lwc';
import FULL_CALENDAR from '@salesforce/resourceUrl/FullCalendar';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import getCalendarEvents from '@salesforce/apex/HOT_FullCalendarController.getCalendarEvents';
import IKONER from '@salesforce/resourceUrl/ikoner';
import { NavigationMixin } from 'lightning/navigation';
import { CalendarEvent } from './calendar_event';
import { formatDatetimeinterval, formatDatetime } from 'c/datetimeFormatterNorwegianTime';
import icons from '@salesforce/resourceUrl/ikoner';
import icons2 from '@salesforce/resourceUrl/icons';

import HOT_ConfirmationModal from 'c/hot_confirmationModal';
import ConfimationModal from 'c/hot_calendar_absence_modal_confirmation';
import retractAvailability from '@salesforce/apex/HOT_WageClaimListController.retractAvailability';
import getWageClaimDetails from '@salesforce/apex/HOT_WageClaimListController.getWageClaimDetails';
import checkAccessToSA from '@salesforce/apex/HOT_MyServiceAppointmentListController.checkAccessToSA';
import getInterestedResourceDetails from '@salesforce/apex/HOT_InterestedResourcesListController.getInterestedResourceDetails';
import getThreadServiceAppointmentId from '@salesforce/apex/HOT_MyServiceAppointmentListController.getThreadServiceAppointmentId';
import getServiceAppointment from '@salesforce/apex/HOT_MyServiceAppointmentListController.getServiceAppointment';
import getServiceAppointmentDetails from '@salesforce/apex/HOT_MyServiceAppointmentListController.getServiceAppointmentDetails';
import getThreadIdWC from '@salesforce/apex/HOT_WageClaimListController.getThreadId';
import getThreadFreelanceId from '@salesforce/apex/HOT_MyServiceAppointmentListController.getThreadFreelanceId';
import getThreadInterpretersId from '@salesforce/apex/HOT_MyServiceAppointmentListController.getThreadInterpretersId';
import createThread from '@salesforce/apex/HOT_MessageHelper.createThread';
import createThreadInterpreter from '@salesforce/apex/HOT_MessageHelper.createThreadInterpreter';
import createThreadInterpreters from '@salesforce/apex/HOT_MessageHelper.createThreadInterpreters';

// Absence imports
import getConflictsForTimePeriod from '@salesforce/apex/HOT_FreelanceAbsenceController.getConflictsForTimePeriod';
import createAbsenceAndResolveConflicts from '@salesforce/apex/HOT_FreelanceAbsenceController.createAbsenceAndResolveConflicts';
import deleteAbsence from '@salesforce/apex/HOT_FreelanceAbsenceController.deleteAbsence';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class LibsFullCalendarV2 extends NavigationMixin(LightningElement) {
    static MILLISECONDS_PER_DAY = 86400000;
    static DAYS_TO_FETCH_FROM_TODAY = 4 * 31;
    static DAYS_TO_FETCH_BEFORE_TODAY = 2 * 31;
    static FETCH_THRESHOLD_IN_DAYS = 31; // How 'close' date view start or end can get to earliestTime or latestTime before a fetch of new events occurs
    static REFRESH_ICON = IKONER + '/Refresh/Refresh.svg';
    static MOBILE_BREAK_POINT = 768;
    static STATE_KEY = 'i98u14ij24j2+49i+04oasfdh';

    exitCrossIcon = icons + '/Close/Close.svg';
    warningicon = icons2 + '/warningicon.svg';

    isLoading = false;
    isSpinning = false;
    isMobileSize = false;
    earliestTime;
    latestTime;
    cachedEventIds = new Set();
    error;
    calendar;
    errorText = '';

    @api records;
    @api recordId;
    @api type;

    // Service appointment properties
    saFreelanceThreadId;
    saThreadId;
    saIsflow = false;
    saIsEditButtonDisabled;
    saIsEditButtonHidden;
    saIsCancelButtonHidden = true;
    interestedResource;
    serviceAppointment;
    accountPhoneNumber;
    isOtherProvider;
    accountAgeGender;
    accountName;
    ownerName;
    ordererPhoneNumber;
    termsOfAgreement;
    isGoToThreadInterpretersButtonDisabled = false;
    isGoToThreadButtonDisabled = false;
    isGoToThreadServiceAppointmentButtonDisabled = false;

    // Wageclaim
    wcIsNotRetractable = false;
    wcIsDisabledGoToThread = false;
    modalWageContent =
        'Er du sikker på at du vil fjerne tilgjengeligheten din for dette tidspunktet? Du vil da ikke ha krav på lønn.';

    isSADetails = false;
    hasAccess = false;
    isWCDetails = false;

    connectedCallback() {
        const state = sessionStorage.getItem(LibsFullCalendarV2.STATE_KEY);

        const loadedSessionState = state ? JSON.parse(state) : null;

        this.isMobileSize = window.innerWidth < LibsFullCalendarV2.MOBILE_BREAK_POINT;

        const viewDateInMilliseconds = state ? new Date(loadedSessionState.viewDate).getTime() : new Date().getTime();
        this.earliestTime =
            viewDateInMilliseconds -
            LibsFullCalendarV2.DAYS_TO_FETCH_BEFORE_TODAY * LibsFullCalendarV2.MILLISECONDS_PER_DAY;
        this.latestTime =
            viewDateInMilliseconds +
            LibsFullCalendarV2.DAYS_TO_FETCH_FROM_TODAY * LibsFullCalendarV2.MILLISECONDS_PER_DAY;

        this.setupCalendar(loadedSessionState).then(() => {
            this.updatePseudoEventsDisplay(this.calendar.view);
        });
    }

    disconnectedCallback() {
        const state = {
            viewDate: this.calendar?.getDate(),
            viewType: this.calendar?.view.type
        };
        sessionStorage.setItem(LibsFullCalendarV2.STATE_KEY, JSON.stringify(state));
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
            el.innerHTML = `<img src="${LibsFullCalendarV2.REFRESH_ICON}" alt="Refresh Icon" style="width:16px; color:white; height:16px;" />`;
        }
    }
    yesOrNo(boolean) {
        if (boolean) {
            return 'Ja';
        } else {
            return 'Nei';
        }
    }

    async updatePseudoEventsDisplay(view) {
        this.calendar?.batchRendering(() => {
            this.calendar?.getEvents().forEach((event) => {
                if (!event.extendedProps.isMultiDay && !event.extendedProps.isPseudoEvent) {
                    return;
                } else if (event.extendedProps.isPseudoEvent) {
                    // Has to hide a pseudo event if it is on the first day of the current view due to a conflict with
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
        this.isSpinning = true && shouldSpin;
        const minLoadingTime = new Promise((resolve) => setTimeout(resolve, 2500));

        this.cachedEventIds.clear();

        const viewDateInMilliseconds = this.calendar.getDate().getTime();
        this.earliestTime =
            viewDateInMilliseconds -
            LibsFullCalendarV2.DAYS_TO_FETCH_BEFORE_TODAY * LibsFullCalendarV2.MILLISECONDS_PER_DAY;
        this.latestTime =
            viewDateInMilliseconds +
            LibsFullCalendarV2.DAYS_TO_FETCH_FROM_TODAY * LibsFullCalendarV2.MILLISECONDS_PER_DAY;

        const events = await this.fetchUniqueEventsForTimeRegion(this.earliestTime, this.latestTime);

        this.calendar.removeAllEvents();

        for (const event of events) {
            this.calendar.addEvent(event);
        }

        if (shouldSpin) {
            await minLoadingTime;
        }
        this.isSpinning = false;
    }

    async updateEventsFromDateRange(earliestDateInView, latestDateInView) {
        const earliestTimeInView = earliestDateInView.getTime();
        const latestTimeInView = latestDateInView.getTime();
        const events = [];

        const fetchThresholdInMilliseconds =
            LibsFullCalendarV2.FETCH_THRESHOLD_IN_DAYS * LibsFullCalendarV2.MILLISECONDS_PER_DAY;

        if (earliestTimeInView < this.earliestTime + fetchThresholdInMilliseconds) {
            const newEarliestTime =
                earliestTimeInView -
                LibsFullCalendarV2.DAYS_TO_FETCH_BEFORE_TODAY * LibsFullCalendarV2.MILLISECONDS_PER_DAY;
            const pastEvents = await this.fetchUniqueEventsForTimeRegion(newEarliestTime, this.earliestTime);
            this.earliestTime = newEarliestTime;
            events.push(...pastEvents);
        }

        if (latestTimeInView > this.latestTime - fetchThresholdInMilliseconds) {
            const newLatestTime =
                latestTimeInView +
                LibsFullCalendarV2.DAYS_TO_FETCH_FROM_TODAY * LibsFullCalendarV2.MILLISECONDS_PER_DAY;
            const futureEvents = await this.fetchUniqueEventsForTimeRegion(this.latestTime, newLatestTime);
            this.latestTime = newLatestTime;
            events.push(...futureEvents);
        }

        for (const event of events) {
            this.calendar?.addEvent(event);
        }
    }

    async fetchUniqueEventsForTimeRegion(earliestTime, latestTime) {
        let data;
        try {
            data = await getCalendarEvents({
                earliestEventEndTimeInMilliseconds: earliestTime,
                latestEventStartInMilliseconds: latestTime
            });
        } catch {
            const event = new ShowToastEvent({
                title: 'Det oppsto en feil',
                message: 'Feil ved henting av avtaler i dette tidsrommet, prøv igjen senere.',
                variant: 'error'
            });
            this.dispatchEvent(event);
        }
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

        var start = new Date(event.start.getTime() + LibsFullCalendarV2.MILLISECONDS_PER_DAY);
        const end = new Date(event.end.getTime() + LibsFullCalendarV2.MILLISECONDS_PER_DAY);

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
            start = new Date(start.getTime() + LibsFullCalendarV2.MILLISECONDS_PER_DAY);
        }
        return pseudoEvents;
    }

    async navigateToDetailView(event) {
        const props = event.extendedProps;

        // Clear previous modal data
        this.serviceAppointment = null;
        this.accountPhoneNumber = '';
        this.accountName = '';
        this.accountAgeGender = '';
        this.ownerName = '';
        this.ordererPhoneNumber = '';
        this.interestedResource = null;
        this.termsOfAgreement = null;
        this.wageClaim = null;
        this.isSADetails = false;
        this.isWCDetails = false;
        this.hasAccess = false;
        this.isLoading = true;

        switch (props.type) {
            case 'COMPLETED_SERVICE_APPOINTMENT':
            case 'SERVICE_APPOINTMENT':
                this.showInformationModalDetails(props.recordId, 'SA');
                await this.loadServiceAppointment(props.recordId); // wait for data
                break;

            case 'OPEN_WAGE_CLAIM':
                this.showInformationModalDetails(props.recordId, 'WC');
                await this.loadWageClaim(props.recordId);
                break;

            case 'RESOURCE_ABSENCE':
                this.openAbsenceModal(event);
                break;
        }
    }

    getModalSize() {
        return window.screen.width < 768 ? 'full' : 'small';
    }
    handleRefreshRecords() {
        this.refreshCalendar(false);
    }

    getDayOfWeek(date) {
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

    isInformationModalOpen = false;
    modalRecordId;
    modalType;

    showInformationModalDetails(recordId, type) {
        const dialog = this.template.querySelector('.modal-information');
        dialog.showModal();
        dialog.focus();

        this.modalRecordId = recordId;
        this.modalType = type;
        this.isInformationModalOpen = true;

        // Disable retract button only if status is "Tilbaketrukket tilgjengelighet"
        if (type === 'WC' && this.wageClaim) {
            this.wcIsNotRetractable = this.wageClaim.Status__c === 'Tilbaketrukket tilgjengelighet';
            this.wcIsDisabledGoToThread = this.wageClaim.Status__c === 'Tilbaketrukket tilgjengelighet';
        }

        if (type === 'SA') {
            this.isSADetails = true;
        }
    }

    closeModal() {
        const dialogModalInfo = this.template.querySelector('.modal-information');
        dialogModalInfo.close();

        const dialogAbsence = this.template.querySelector('.modal-absence');
        dialogAbsence.close();

        this.errorText = '';
        this.isInformationModalOpen = false;
        this.isAlertAbsenceEdit = false;
        this.isNotRetractableDelete = false;
        this.isNotRetractableEdit = false;
        this.isAlertWageClaimEdit = false;
        this.cancelStatusFlow();

        this.dispatchEvent(new CustomEvent('closemodal'));
    }

    openGoogleMaps() {
        window.open(
            'https://www.google.com/maps/search/?api=1&query=' + this.serviceAppointment.HOT_AddressFormated__c
        );
    }

    openAppleMaps() {
        window.open('http://maps.apple.com/?q=' + this.serviceAppointment.HOT_AddressFormated__c);
    }

    isAlertWageClaimEdit = false;
    retractWageClaimClicked() {
        this.isAlertWageClaimEdit = true;
    }

    retractWageClaimCancel() {
        this.isAlertWageClaimEdit = false;
    }

    async showModalRetract() {
        this.isAlertWageClaimEdit = false;

        this.retractAvailability();
        this.showInformationModalDetails();
    }

    retractAvailability() {
        try {
            retractAvailability({ recordId: this.wageClaim.Id }).then(() => {
                this.wcIsNotRetractable = true;
                this.wageClaim.Status__c = 'Tilbaketrukket tilgjengelighet';
                this.refreshApexCallout();
            });
        } catch (error) {
            alert(JSON.stringify(error));
        }
    }

    // @api
    // goToRecordDetailsWCFromId(recordId) {
    //     this.isAListView = false;
    //     this.isWCDetails = true;
    //     this.isLoading = true;
    //     getWageClaimDetails({ recordId: recordId }).then((result) => {
    //         this.wageClaim = result;
    //         this.wageClaim.StartAndEndDate = formatDatetimeinterval(
    //             this.wageClaim.StartTime__c,
    //             this.wageClaim.EndTime__c
    //         );
    //         this.isWCDetails = true;
    //         this.isLoading = false;
    //     });
    // }

    // @api
    // goToRecordDetailsSA(saID, recordsArray) {
    //     console.log('22222');
    //     let recordId = saID;
    //     this.serviceAppointment = undefined;
    //     this.interestedResource = undefined;
    //     this.saIsEditButtonHidden = false;
    //     this.saIsCancelButtonHidden = true;
    //     this.saIsEditButtonDisabled = false;
    //     this.isLoading = true;
    //     for (let serviceAppointment of recordsArray) {
    //         if (recordId === serviceAppointment.Id) {
    //             this.accountPhoneNumber = '';
    //             this.accountAgeGender = '';
    //             this.accountName = '';
    //             this.ordererPhoneNumber = '';
    //             this.ownerName = '';
    //             this.serviceAppointment = { ...serviceAppointment };
    //             this.serviceAppointment.weekday = this.getDayOfWeek(this.serviceAppointment.EarliestStartTime);
    //             this.interestedResource = serviceAppointment?.InterestedResources__r[0];
    //             this.termsOfAgreement = this.interestedResource.HOT_TermsOfAgreement__c;
    //             this.isOtherProvider = this.serviceAppointment.HOT_Request__r.IsOtherEconomicProvicer__c ? 'Ja' : 'Nei';

    //             if (this.serviceAppointment.HOT_Request__r && this.serviceAppointment.HOT_Request__r.Account__r) {
    //                 if (
    //                     this.serviceAppointment.HOT_Request__r.Account__r.Name == null ||
    //                     this.serviceAppointment.HOT_Request__r.Account__r.Name == ''
    //                 ) {
    //                     this.isGoToThreadButtonDisabled = true;
    //                 } else {
    //                     this.isGoToThreadButtonDisabled = false;
    //                 }
    //             } else {
    //                 this.isGoToThreadButtonDisabled = true;
    //             }
    //             if (this.serviceAppointment.Status == 'Completed') {
    //                 this.saIsEditButtonDisabled = true;
    //             }
    //             if (this.serviceAppointment.HOT_TotalNumberOfInterpreters__c <= 1) {
    //                 this.isGoToThreadInterpretersButtonDisabled = true;
    //             }
    //             if (this.serviceAppointment.HOT_Request__r.IsNotNotifyAccount__c == true) {
    //                 this.isGoToThreadButtonDisabled = true;
    //             }
    //             if (
    //                 this.serviceAppointment &&
    //                 this.serviceAppointment.HOT_Request__r &&
    //                 this.serviceAppointment.HOT_Request__r.Account__r &&
    //                 this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r.INT_Confidential == 'UGRADERT'
    //             ) {
    //                 this.accountName = this.serviceAppointment.HOT_Request__r.Account__r.Name;
    //             }
    //             if (
    //                 this.serviceAppointment &&
    //                 this.serviceAppointment.HOT_Request__r &&
    //                 this.serviceAppointment.HOT_Request__r.Account__r &&
    //                 this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r.INT_Confidential != 'FORTROLIG'
    //             ) {
    //                 this.accountName = this.serviceAppointment.HOT_NavEmployeeName__c;
    //             }
    //             if (this.serviceAppointment && this.serviceAppointment.HOT_Request__r) {
    //                 this.ownerName = this.serviceAppointment.HOT_Request__r.OwnerName__c;
    //             }
    //             if (
    //                 this.serviceAppointment &&
    //                 this.serviceAppointment.HOT_Request__r &&
    //                 this.serviceAppointment.HOT_Request__r.Account__r &&
    //                 this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r
    //             ) {
    //                 if (this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r.CRM_AgeNumber__c == undefined) {
    //                     if (this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r.INT_Sex__c !== undefined) {
    //                         this.accountAgeGender =
    //                             this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r.INT_Sex__c;
    //                     }
    //                 } else if (
    //                     this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r.INT_Sex__c == undefined
    //                 ) {
    //                     if (
    //                         this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r.CRM_AgeNumber__c !==
    //                         undefined
    //                     ) {
    //                         this.accountAgeGender =
    //                             this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r.CRM_AgeNumber__c +
    //                             ' år';
    //                     }
    //                 } else if (
    //                     this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r.INT_Sex__c !== undefined &&
    //                     this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r.CRM_AgeNumber__c !== undefined
    //                 ) {
    //                     this.accountAgeGender =
    //                         this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r.INT_Sex__c +
    //                         ' ' +
    //                         this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r.CRM_AgeNumber__c +
    //                         ' år';
    //                 }
    //                 if (
    //                     this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r.INT_KrrMobilePhone__c !==
    //                     undefined
    //                 ) {
    //                     this.accountPhoneNumber =
    //                         this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r.INT_KrrMobilePhone__c;
    //                 }
    //             }
    //             if (
    //                 this.serviceAppointment &&
    //                 this.serviceAppointment.HOT_Request__r &&
    //                 this.serviceAppointment.HOT_Request__r.Orderer__r &&
    //                 this.serviceAppointment.HOT_Request__r.Orderer__r.CRM_Person__r
    //             ) {
    //                 if (
    //                     this.serviceAppointment.HOT_Request__r.Orderer__r.CRM_Person__r.INT_KrrMobilePhone__c !==
    //                     undefined
    //                 ) {
    //                     this.ordererPhoneNumber =
    //                         this.serviceAppointment.HOT_Request__r.Orderer__r.CRM_Person__r.INT_KrrMobilePhone__c;
    //                 }
    //             }
    //             this.isLoading = false;
    //             this.isSADetails = true;
    //             this.hasAccess = true;
    //         }
    //     }
    //     this.updateURL();
    // }

    // @api
    // goToRecordDetailsSAFromId(recordId) {
    //     console.log('bblksdgforefkrwd');
    //     this.isSADetails = true;
    //     this.isAListView = false;
    //     if (this.type == null) {
    //         this.isLoading = true;
    //     }
    //     checkAccessToSA({ saId: recordId }).then((result) => {
    //         if (result != false) {
    //             getServiceAppointmentDetails({ recordId: recordId }).then((result) => {
    //                 this.accountPhoneNumber = '';
    //                 this.accountAgeGender = '';
    //                 this.accountName = '';
    //                 this.ordererPhoneNumber = '';
    //                 this.ownerName = '';
    //                 this.serviceAppointment = result;
    //                 this.serviceAppointment.StartAndEndDate = formatDatetimeinterval(
    //                     result.EarliestStartTime,
    //                     result.DueDate
    //                 );
    //                 this.isOtherProvider = this.serviceAppointment.HOT_Request__r.IsOtherEconomicProvicer__c
    //                     ? 'Ja'
    //                     : 'Nei';
    //                 this.serviceAppointment.ActualStartTime = formatDatetime(result.ActualStartTime);
    //                 this.serviceAppointment.ActualEndTime = formatDatetime(result.ActualEndTime);
    //                 if (
    //                     this.serviceAppointment &&
    //                     this.serviceAppointment.HOT_Request__r &&
    //                     this.serviceAppointment.HOT_Request__r.Account__r
    //                 ) {
    //                     this.accountName = this.serviceAppointment.HOT_Request__r.Account__r.Name;
    //                 }
    //                 if (
    //                     this.serviceAppointment &&
    //                     this.serviceAppointment.HOT_Request__r &&
    //                     this.serviceAppointment.HOT_Request__r.Account__r &&
    //                     this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r
    //                 ) {
    //                     if (
    //                         this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r.CRM_AgeNumber__c ==
    //                         undefined
    //                     ) {
    //                         if (
    //                             this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r.INT_Sex__c !== undefined
    //                         ) {
    //                             this.accountAgeGender =
    //                                 this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r.INT_Sex__c;
    //                         }
    //                     } else if (
    //                         this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r.INT_Sex__c == undefined
    //                     ) {
    //                         if (
    //                             this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r.CRM_AgeNumber__c !==
    //                             undefined
    //                         ) {
    //                             this.accountAgeGender =
    //                                 this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r.CRM_AgeNumber__c +
    //                                 ' år';
    //                         }
    //                     } else if (
    //                         this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r.INT_Sex__c !== undefined &&
    //                         this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r.CRM_AgeNumber__c !==
    //                             undefined
    //                     ) {
    //                         this.accountAgeGender =
    //                             this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r.INT_Sex__c +
    //                             ' ' +
    //                             this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r.CRM_AgeNumber__c +
    //                             ' år';
    //                     }
    //                     if (
    //                         this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r.INT_KrrMobilePhone__c !==
    //                         undefined
    //                     ) {
    //                         this.accountPhoneNumber =
    //                             this.serviceAppointment.HOT_Request__r.Account__r.CRM_Person__r.INT_KrrMobilePhone__c;
    //                     }
    //                     if (this.serviceAppointment && this.serviceAppointment.HOT_Request__r) {
    //                         this.ownerName = this.serviceAppointment.HOT_Request__r.OwnerName__c;
    //                     }
    //                 }
    //                 if (
    //                     this.serviceAppointment &&
    //                     this.serviceAppointment.HOT_Request__r &&
    //                     this.serviceAppointment.HOT_Request__r.Orderer__r &&
    //                     this.serviceAppointment.HOT_Request__r.Orderer__r.CRM_Person__r
    //                 ) {
    //                     if (
    //                         this.serviceAppointment.HOT_Request__r.Orderer__r.CRM_Person__r.INT_KrrMobilePhone__c !==
    //                         undefined
    //                     ) {
    //                         this.ordererPhoneNumber =
    //                             this.serviceAppointment.HOT_Request__r.Orderer__r.CRM_Person__r.INT_KrrMobilePhone__c;
    //                     }
    //                 }
    //                 getInterestedResourceDetails({ recordId: recordId }).then((result) => {
    //                     this.interestedResource = result;
    //                     this.termsOfAgreement = this.interestedResource.HOT_TermsOfAgreement__c;
    //                 });

    //                 this.saIsEditButtonHidden = false;
    //                 this.saIsCancelButtonHidden = true;
    //                 this.saIsEditButtonDisabled = false;
    //                 this.serviceAppointment.weekday = this.getDayOfWeek(this.serviceAppointment.EarliestStartTime);
    //                 let duedate = new Date(this.serviceAppointment.DueDate);
    //                 if (this.serviceAppointment.Status == 'Completed') {
    //                     this.saIsEditButtonDisabled = true;
    //                 }
    //                 if (this.serviceAppointment.HOT_TotalNumberOfInterpreters__c <= 1) {
    //                     this.isGoToThreadInterpretersButtonDisabled = true;
    //                 }
    //                 if (this.serviceAppointment.HOT_Request__r.IsNotNotifyAccount__c == true) {
    //                     this.isGoToThreadButtonDisabled = true;
    //                 }
    //                 this.hasAccess = true;
    //                 this.isLoading = false;
    //             });
    //         } else {
    //             this.isLoading = false;
    //             this.hasAccess = false;
    //         }
    //     });
    // }

    // Serviceappointment endre status flow
    changeStatus() {
        this.saIsflow = true;
        this.saIsEditButtonDisabled = true;
        this.saIsCancelButtonHidden = false;
        this.isDetails = true;
        this.saIsEditButtonHidden = true;
    }

    cancelStatusFlow() {
        this.saIsflow = false;
        this.saIsEditButtonDisabled = false;
        this.saIsCancelButtonHidden = true;
        this.isDetails = true;
        this.saIsEditButtonHidden = false;
    }

    get flowVariables() {
        return [
            {
                name: 'recordId',
                type: 'String',
                value: this.serviceAppointment.Id
            }
        ];
    }

    handleStatusChange(event) {
        if (event.detail.interviewStatus == 'FINISHED') {
            getServiceAppointment({
                recordId: this.serviceAppointment.Id
            }).then((data) => {
                if (data.Status == 'Completed') {
                    this.saIsflow = false;
                    this.saIsCancelButtonHidden = true;
                    this.serviceAppointment.Status = 'Dekket';
                }
                if (data.Status == 'Canceled') {
                    this.saIsflow = false;
                    this.saIsCancelButtonHidden = true;
                    this.serviceAppointment.Status = 'Avlyst';
                }
                if (data.HOT_CanceledByInterpreter__c) {
                    this.saIsflow = false;
                    this.saIsCancelButtonHidden = true;
                    this.serviceAppointment.Status = 'Tolk tar seg av';
                }
            });
            this.refreshApexCallout();
        }
    }

    // brukes til å hente nye data etter endring av statuser
    refreshApexCallout() {
        this.refreshCalendar();
        const eventToSend = new CustomEvent('refreshrecords');
        this.dispatchEvent(eventToSend);
    }

    goToThreadServiceAppointment() {
        this.isGoToThreadServiceAppointmentButtonDisabled = true;
        getThreadServiceAppointmentId({ serviceAppointmentId: this.serviceAppointment.Id }).then((result) => {
            if (result != '') {
                this.saThreadId = result;
                this.navigateToThread(this.saThreadId);
            } else {
                createThreadInterpreter({ recordId: this.serviceAppointment.Id })
                    .then((result) => {
                        this.saThreadId = result;
                        this.navigateToThread(result.Id);
                    })
                    .catch((error) => {
                        const result = HOT_ConfirmationModal.open({
                            size: 'small',
                            headline: 'Noe gikk galt',
                            message: 'Kunne ikke åpne samtale. Feilmelding: ' + error,
                            primaryLabel: 'Ok'
                        });
                    });
            }
        });
    }

    updateURL() {
        let list = 'my';
        if (this.type == 'SA') {
            list = 'my';
        }
        if (this.type == 'WC') {
            list = 'wageClaim';
        }

        let baseURL =
            window.location.protocol + '//' + window.location.host + window.location.pathname + '?list=' + list;
        if (this.recordId) {
            baseURL += '&id=' + this.recordId;
        }
        window.history.pushState({ path: baseURL }, '', baseURL);
    }

    treadId;
    goToWageClaimThread() {
        this.wcIsDisabledGoToThread = true;
        getThreadIdWC({ wageClaimeId: this.wageClaim.Id }).then((result) => {
            if (result != '') {
                this.threadId = result;
                this.navigateToThread(this.threadId);
            } else {
                createThread({ recordId: this.wageClaim.Id, accountId: this.wageClaim.ServiceResource__r.AccountId })
                    .then((result) => {
                        this.navigateToThread(result.Id);
                    })
                    .catch((error) => {
                        const result = HOT_ConfirmationModal.open({
                            size: 'small',
                            headline: 'Noe gikk galt',
                            message: 'Kunne ikke åpne samtale. Feilmelding: ' + error,
                            primaryLabel: 'Ok'
                        });
                    });
            }
        });
    }

    goToThreadFreelance() {
        this.isGoToThreadButtonDisabled = true;
        getThreadFreelanceId({ serviceAppointmentId: this.serviceAppointment.Id }).then((result) => {
            if (result != '') {
                this.saFreelanceThreadId = result;
                this.navigateToThread(this.saFreelanceThreadId);
            } else {
                createThread({ recordId: this.serviceAppointment.Id, accountId: this.serviceAppointment.accountId })
                    .then((result) => {
                        this.navigateToThread(result.Id);
                        this.saFreelanceThreadId = result;
                    })
                    .catch((error) => {
                        const result = HOT_ConfirmationModal.open({
                            size: 'small',
                            headline: 'Noe gikk galt',
                            message: 'Kunne ikke åpne samtale. Feilmelding: ' + error,
                            primaryLabel: 'Ok'
                        });
                    });
            }
        });
    }

    goToThreadInterpreters() {
        this.isGoToThreadInterpretersButtonDisabled = true;
        getThreadInterpretersId({ serviceAppointmentId: this.serviceAppointment.Id }).then((result) => {
            if (result != '') {
                this.saFreelanceThreadId = result;
                this.navigateToThread(this.saFreelanceThreadId);
            } else {
                createThreadInterpreters({ recordId: this.serviceAppointment.Id })
                    .then((result) => {
                        this.navigateToThread(result.Id);
                        this.saFreelanceThreadId = result;
                    })
                    .catch((error) => {
                        const result = HOT_ConfirmationModal.open({
                            size: 'small',
                            headline: 'Noe gikk galt',
                            message: 'Kunne ikke åpne samtale. Feilmelding: ' + error,
                            primaryLabel: 'Ok'
                        });
                    });
            }
        });
    }

    navigateToThread(recordId) {
        if (this.isAListView && this.isSADetails) {
            const baseUrl = '/samtale-frilans';
            const attributes = `recordId=${recordId}&from=mine-oppdrag&list=my`;
            const url = `${baseUrl}?${attributes}`;

            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: url
                }
            });
        } else if (this.isAListView && this.isWCDetails) {
            const baseUrl = '/samtale-frilans';
            const attributes = `recordId=${recordId}&from=mine-oppdrag&list=wageClaim`;
            const url = `${baseUrl}?${attributes}`;

            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: url
                }
            });
        } else {
            const baseUrl = '/samtale-frilans';
            const attributes = `recordId=${recordId}&from=kalender`;
            const url = `${baseUrl}?${attributes}`;

            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: url
                }
            });
        }
    }

    async loadServiceAppointment(recordId) {
        try {
            const access = await checkAccessToSA({ saId: recordId });
            this.hasAccess = !!access;

            if (this.hasAccess) {
                const sa = await getServiceAppointmentDetails({ recordId });
                this.serviceAppointment = sa;

                this.serviceAppointment.StartAndEndDate = formatDatetimeinterval(sa.EarliestStartTime, sa.DueDate);
                this.serviceAppointment.ActualStartTime = formatDatetime(sa.ActualStartTime);
                this.serviceAppointment.ActualEndTime = formatDatetime(sa.ActualEndTime);
                this.serviceAppointment.HOT_HapticCommunication__c = this.yesOrNo(
                    this.serviceAppointment.HOT_HapticCommunication__c
                );

                this.isOtherProvider = this.serviceAppointment.HOT_Request__r.IsOtherEconomicProvicer__c ? 'Ja' : 'Nei';
                getInterestedResourceDetails({ recordId: recordId }).then((result) => {
                    this.interestedResource = result;
                    this.termsOfAgreement = this.interestedResource.HOT_TermsOfAgreement__c;
                });
                this.ordererPhoneNumber = sa.HOT_Request__r?.Orderer__r?.CRM_Person__r?.INT_KrrMobilePhone__c ?? '';
                const crmPerson = sa.HOT_Request__r?.Account__r?.CRM_Person__r;
                if (crmPerson) {
                    this.accountAgeGender =
                        (crmPerson.INT_Sex__c || '') +
                        ' ' +
                        (crmPerson.CRM_AgeNumber__c ? crmPerson.CRM_AgeNumber__c + ' år' : '');
                    this.accountPhoneNumber = crmPerson.INT_KrrMobilePhone__c || '';
                }
                this.accountName = sa.HOT_Request__r?.Account__r?.Name || '';
                this.ownerName = sa.HOT_Request__r?.OwnerName__c || '';
            }
        } catch (error) {
            console.error('Error loading service appointment', error);
            this.hasAccess = false;
        } finally {
            this.isLoading = false;
            this.isSADetails = true;
        }
    }

    async loadWageClaim(recordId) {
        try {
            const wc = await getWageClaimDetails({ recordId });
            this.wageClaim = wc;
            this.wageClaim.StartAndEndDate = formatDatetimeinterval(wc.StartTime__c, wc.EndTime__c);
            this.isWCDetails = true;
        } catch (error) {
            console.error('Error loading wage claim', error);
        } finally {
            this.isLoading = false;
        }
    }

    async getCalendarConfig(events, sessionState) {
        let config = {
            eventDidMount: (context) => {
                this.onEventMount(context);
            },
            windowResize: (context) => {
                this.isMobileSize = window.innerWidth < LibsFullCalendarV2.MOBILE_BREAK_POINT;
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
                        if (this.calendar?.view.type == 'timeGridDay') {
                            const millisecondsPerHour = 60 * 60 * 1000;
                            const viewedDate = this.calendar.view.activeStart;
                            const suggestedStartTime = new Date(viewedDate.getTime() + 12 * millisecondsPerHour);
                            const suggestEndTime = new Date(suggestedStartTime.getTime() + millisecondsPerHour);
                            this.openAbsenceModal(null, suggestedStartTime, suggestEndTime);
                        } else {
                            this.openAbsenceModal();
                        }
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
                start: 'title',
                center: '',
                end: 'today dayGridMonth'
            };
            config.footerToolbar = {
                left: 'prev,next',
                center: '',
                right: 'absence refresh'
            };
            config.height = 'auto';
            config.titleFormat = { year: 'numeric', month: 'long' };
            config.views.dayGridMonth.dayMaxEventRows = 10;
        }

        if (sessionState) {
            config.initialDate = new Date(sessionState.viewDate);
            config.initialView = sessionState.viewType;
        }

        return config;
    }

    radiobuttons = [
        { label: 'Ferie', value: 'Vacation', checked: false },
        { label: 'Sykdom', value: 'Medical', checked: false },
        { label: 'Annet', value: 'Other', checked: false }
    ];

    applyAbsenceTypeToRadios() {
        this.radiobuttons = this.radiobuttons.map((rb) => ({
            ...rb,
            checked: this.absenceType ? rb.value === this.absenceType : false
        }));
    }

    syncAllDayCheckbox() {
        const allDayCmp = this.template.querySelector('c-checkbox');
        if (allDayCmp) {
            allDayCmp.setCheckboxValue(!!this.isAllDayAbsence);
        }
    }

    // Absence modal functionalities
    async openAbsenceModal(event, initialAbsenceStart, initialAbsenceEnd) {
        this.isEdit = false;
        this.isAllDayAbsence = false;
        this.timeFormat = 'datetime';
        this.endHasBeenSet = false;
        this.clearCheckedRadios();

        if (event && event.extendedProps.recordId) {
            this.isEdit = true;
            this.setAbsenceTypeFromDescription(event.extendedProps.description);
            initialAbsenceStart = this.formatLocalDateTime(event.start);
            initialAbsenceEnd = this.formatLocalDateTime(event.end);

            // Assign to class properties
            this.initialAbsenceStart = initialAbsenceStart;
            this.initialAbsenceEnd = initialAbsenceEnd;

            this.currentEventRecordId = event.extendedProps.recordId;
        } else {
            const now = new Date();
            const startTime = new Date(now.getTime() + (60 - now.getMinutes()) * 60000);

            initialAbsenceStart = this.formatLocalDateTime(initialAbsenceStart ?? startTime);
            initialAbsenceEnd = this.formatLocalDateTime(
                initialAbsenceEnd ?? new Date(startTime.getTime() + 60 * 60000)
            );

            this.initialAbsenceStart = initialAbsenceStart;
            this.initialAbsenceEnd = initialAbsenceEnd;
            this.isAllDayAbsence = false;
            this.timeFormat = 'datetime';
        }
        this.syncAllDayCheckbox();
        this.applyAbsenceTypeToRadios();
        this.headerAbsenceText = this.isEdit ? 'Endre/Slett fravær' : 'Registrer nytt fravær';
        this.startTimeInputLabel = `Legg inn${this.isEdit ? ' ny' : ''} startdato/tid`;
        this.endTimeInputLabel = `Legg inn${this.isEdit ? ' ny' : ''} sluttdato/tid`;
        this.registerButtonText = this.isEdit ? 'Endre' : 'Registrer';

        const startInput = this.refs?.absenceStartDateTimeInput;
        const endInput = this.refs?.absenceEndDateTimeInput;
        if (startInput) {
            startInput.setCustomValidity('');
            startInput.reportValidity();
        }
        if (endInput) {
            endInput.setCustomValidity('');
            endInput.reportValidity();
        }
        this.endHasBeenSet = false;

        const absenceDialog = this.template.querySelector('.modal-absence');
        if (!absenceDialog) return;

        absenceDialog.returnValue = ''; // reset state

        absenceDialog.showModal();
        absenceDialog.focus();

        const result = await new Promise((resolve) => {
            const handler = () => {
                absenceDialog.removeEventListener('close', handler);
                resolve(absenceDialog.returnValue === 'confirm');
            };
            absenceDialog.addEventListener('close', handler);
        });

        if (result) {
            await this.refreshCalendar(false);
            this.updatePseudoEventsDisplay(this.calendar.view);
        }
    }

    setAbsenceTypeFromDescription(description) {
        if (!description) {
            this.clearCheckedRadios();
            return;
        }

        const mapping = [
            { label: 'Ferie', value: 'Vacation' },
            { label: 'Sykdom', value: 'Medical' },
            { label: 'Annet', value: 'Other' }
        ];

        const match = mapping.find((item) => description.toLowerCase().includes(item.label.toLowerCase()));
        if (match) {
            this.absenceType = match.value;
        } else {
            this.absenceType = null;
        }

        this.applyAbsenceTypeToRadios();
    }

    clearCheckedRadios() {
        this.radiobuttons = this.radiobuttons.map((rb) => ({
            ...rb,
            checked: false
        }));
        this.absenceType = null;
    }

    handleRequestTypeChange(event) {
        let radiobuttonValues = event.detail;
        radiobuttonValues.forEach((element) => {
            if (element.checked) {
                this.absenceType = element.value;
            }
        });
        this.applyAbsenceTypeToRadios();
    }

    // Absence fields
    isEdit = false;
    absenceType;
    absenceValue = '';
    timeFormat = 'datetime';
    startTimeInputLabel;
    endTImeInputLabel;
    headerAbsenceText = '';
    registerButtonText = '';

    // Absence event fields
    currentEventRecordId;
    initialAbsenceStart;
    initialAbsenceEnd;

    isAllDayAbsence = false;
    times = [];
    timesBackup;

    handleAllDayEventSet(event) {
        this.isAllDayAbsence = event.detail;
        this.timeFormat = this.isAllDayAbsence ? 'date' : 'datetime';
        const startTime = this.refs.absenceStartDateTimeInput.value;
        const endTime = this.refs.absenceEndDateTimeInput.value;
        if (this.isAllDayAbsence) {
            this.initialAbsenceStart = this.formatLocalDateTime(new Date(startTime), '00', '00');
            this.initialAbsenceEnd = this.formatLocalDateTime(new Date(endTime), '23', '59');
        } else {
            const hours = new Date().getHours();
            const hoursString = (hours < 10 ? '0' : '') + hours.toString();
            this.initialAbsenceStart = this.formatLocalDateTime(new Date(startTime), hoursString, '00');
            this.initialAbsenceEnd = this.formatLocalDateTime(new Date(endTime), hoursString, '00');
        }
    }

    // Hjelper metode for å få dato i riktig tidsone for dateTime input felt
    formatLocalDateTime(date, hoursOverride, minutesOverride) {
        const year = date.getFullYear();
        const month = ('0' + (date.getMonth() + 1)).slice(-2); // Måneder er 0 indeksiert
        const day = ('0' + date.getDate()).slice(-2);
        const hours = hoursOverride !== undefined ? hoursOverride : ('0' + date.getHours()).slice(-2);
        const minutes = minutesOverride !== undefined ? minutesOverride : ('0' + date.getMinutes()).slice(-2);

        return `${year}-${month}-${day}T${hours}:${minutes}`;
    }

    validateAbsenceType(absenceType) {
        return ['Vacation', 'Other', 'Medical'].includes(absenceType);
    }

    handleDateStartChange(event) {
        const startTime = new Date(event.detail.value);
        const endInput = this.refs.absenceEndDateTimeInput;

        if (!endInput || !endInput.value) {
            const newEnd = new Date(startTime.getTime() + 60 * 60 * 1000);
            this.initialAbsenceEnd = this.formatLocalDateTime(newEnd);
            if (endInput) endInput.value = this.initialAbsenceEnd;
        } else {
            const currentEnd = new Date(endInput.value);
            if (!(currentEnd.getTime() > startTime.getTime())) {
                const newEnd = new Date(startTime.getTime() + 60 * 60 * 1000);
                this.initialAbsenceEnd = this.formatLocalDateTime(newEnd);
                endInput.value = this.initialAbsenceEnd;
            }
        }
        const startInput = this.refs.absenceStartDateTimeInput;
        if (endInput && endInput.value) {
            const endTime = new Date(endInput.value);
            startInput.setCustomValidity(
                startTime.getTime() < endTime.getTime() ? '' : 'Sluttid må komme etter starttid'
            );
            startInput.reportValidity();
        } else {
            startInput.setCustomValidity('');
            startInput.reportValidity();
        }

        this.initialAbsenceStart = event.detail.value;
    }

    handleDateEndChange(event) {
        const startInput = this.refs.absenceStartDateTimeInput;
        const startTime = new Date(startInput.value);
        const newEndDate = new Date(event.detail.value);
        startInput.setCustomValidity(
            startTime.getTime() < newEndDate.getTime() ? '' : 'Sluttid må komme etter starttid'
        );
        startInput.reportValidity();
        this.endHasBeenSet = true;
        this.initialAbsenceEnd = event.detail.value;
    }

    isAlertAbsenceEdit = false;
    isNotRetractableDelete = false;
    isNotRetractableEdit = false;
    alertAbsenceBannerText = '';
    retractDeleteAbsense() {
        this.alertAbsenceBannerText = 'Er du sikker på at du vil slette dette fraværet?';
        this.isAlertAbsenceEdit = true;
        this.isNotRetractableDelete = true;
    }

    retractAbsenseCancel() {
        this.isAlertAbsenceEdit = false;
        this.isNotRetractableDelete = false;
        this.isNotRetractableEdit = false;
    }

    retractEditAbsense() {
        this.alertAbsenceBannerText = 'Har du lagt inn de riktige opplysningene før du lagrer endringen?';
        this.isAlertAbsenceEdit = true;
        this.isNotRetractableEdit = true;
    }

    async handleDeleteAbsence() {
        this.isSpinning = true;
        try {
            if (!this.currentEventRecordId) {
                throw new Error('No recordId found for event');
            }

            this.closeModal();
            await deleteAbsence({ recordId: this.currentEventRecordId });

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Fravær slettet',
                    message: 'Fraværet ble slettet vellykket',
                    variant: 'success'
                })
            );
            this.refreshCalendar(false);
        } catch (error) {
            console.error('Delete failed:', error);

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Noe gikk galt',
                    message: 'Kunne ikke slette, prøv igjen senere',
                    variant: 'error'
                })
            );
        }

        this.isAlertAbsenceEdit = false;
        this.isNotRetractableDelete = false;
        this.isNotRetractableEdit = false;
        this.isSpinning = false;
    }

    get absenceTypeToNorwegianLabel() {
        const selected = this.radiobuttons.find((btn) => btn.value === this.absenceType);
        return selected ? selected.label : '';
    }

    async handleOkay() {
        // Fetch radio button value
        let validInputs = true;
        let absenceType = this.absenceType;
        if (!this.validateAbsenceType(absenceType)) {
            validInputs = false;
            this.errorText = 'Velg en type fravær';
            console.log('No absence type selected');
        } else {
            this.errorText = '';
        }
        console.log('Selected absence type:', absenceType);

        // Fetch input field values
        let absenceStartDateTime = this.refs.absenceStartDateTimeInput.value;
        let absenceEndDateTime = this.refs.absenceEndDateTimeInput.value;
        if (this.isAllDayAbsence) {
            absenceStartDateTime = this.formatLocalDateTime(new Date(absenceStartDateTime), '00', '00');
            absenceEndDateTime = this.formatLocalDateTime(new Date(absenceEndDateTime), '23', '59');
        }

        const startMs = new Date(absenceStartDateTime).getTime();
        const endMs = new Date(absenceEndDateTime).getTime();
        const absenceStartElement = this.refs.absenceStartDateTimeInput;
        if (!(startMs < endMs)) {
            absenceStartElement.setCustomValidity('Sluttid må komme etter starttid');
            absenceStartElement.reportValidity();
            validInputs = false;
        } else {
            absenceStartElement.setCustomValidity('');
            absenceStartElement.reportValidity();
        }

        if (!validInputs) {
            return;
        }

        let result;
        try {
            result = await getConflictsForTimePeriod({
                startTimeInMilliseconds: new Date(absenceStartDateTime).getTime(),
                endTimeInMilliseconds: new Date(absenceEndDateTime).getTime(),
                checkWholeDayForConflicts: this.isAllDayAbsence
            });
        } catch {
            const event = new ShowToastEvent({
                title: 'Det oppsto en feil',
                message: 'Feil ved henting av avtaler i dette tidsrommet, prøv igjen senere.',
                variant: 'error'
            });
            this.dispatchEvent(event);
            return;
        }

        const currentHeaderText = this.headerAbsenceText;
        let shouldProceed = false;

        if (currentHeaderText === 'Registrer nytt fravær') {
            const dialogAbsence = this.template.querySelector('.modal-absence');
            dialogAbsence.close();

            const confirmation = await ConfimationModal.open({
                content: result,
                absenceType: this.absenceTypeToNorwegianLabel,
                absenceStartDateTime,
                absenceEndDateTime
            });
            dialogAbsence.showModal();
            dialogAbsence.focus();

            if (confirmation) {
                dialogAbsence.close();
            } else {
                return;
            }
        }
        shouldProceed = true;

        if (shouldProceed) {
            const dialogProceed = this.template.querySelector('.modal-absence');
            dialogProceed.close();
            this.isSpinning = true;
            try {
                await createAbsenceAndResolveConflicts({
                    absenceType: this.absenceType,
                    startTimeInMilliseconds: new Date(absenceStartDateTime).getTime(),
                    endTimeInMilliseconds: new Date(absenceEndDateTime).getTime(),
                    isAllDayAbsence: this.isAllDayAbsence
                });
            } catch (error) {
                const event = new ShowToastEvent({
                    title: 'Kunne ikke legge til fravær',
                    message: 'Det oppstod en feil, prøv igjen senere',
                    variant: 'error'
                });
                this.dispatchEvent(event);
            }
            if (this.isEdit) {
                try {
                    await deleteAbsence({ recordId: this.currentEventRecordId });
                    const event = new ShowToastEvent({
                        title: 'Fravær endret',
                        message: 'Fravær ble endret, og eventuelle konflikter ble løst',
                        variant: 'success'
                    });
                    this.dispatchEvent(event);
                    this.refreshCalendar(false);
                } catch {
                    const event = new ShowToastEvent({
                        title: 'Det oppsto en feil',
                        message: 'Feil ved endring av avtale, prøv igjen senere.',
                        variant: 'error'
                    });
                    this.dispatchEvent(event);
                }
            } else {
                const event = new ShowToastEvent({
                    title: 'Fravær lagt til',
                    message: 'Fravær lagt til, og eventuelle konflikter ble løst',
                    variant: 'success'
                });
                this.dispatchEvent(event);
                this.refreshCalendar(false);
            }

            this.isAlertAbsenceEdit = false;
            this.isNotRetractableDelete = false;
            this.isNotRetractableEdit = false;
            this.isSpinning = false;
            this.currentEventRecordId = null;
            this.isAllDayAbsence = false;
            absenceType = null;
            this.clearCheckedRadios();
            this.closeModal();
        }
    }
}
