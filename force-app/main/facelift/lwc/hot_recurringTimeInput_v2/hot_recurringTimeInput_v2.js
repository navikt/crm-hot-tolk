import { LightningElement, track, wire, api } from 'lwc';
import getTimes from '@salesforce/apex/HOT_RequestListController.getTimesNew';
import previewRecurringWorkOrders from '@salesforce/apex/HOT_CreateWorkOrderService.previewRecurringWorkOrders';
import {
    requireInput,
    dateInPast,
    startBeforeEnd,
    requireRecurringDays,
    startDateBeforeRecurringEndDate,
    restrictTheNumberOfDays
} from './hot_recurringTimeInput_validationRules';

export default class hot_recurringTimeInput_v2 extends LightningElement {
    @track times = [];
    @track isOnlyOneTime = true;
    @track isAdvancedTimes;
    @api refreshToken;
    @api hideAdvancedTimesInEditMode = false;
    @api isEditMode = false;
    singleExistingWorkOrderId;
    uniqueIdCounter = 0;
    recurringPreview;
    previewLoading = false;
    previewError = '';
    previewTimer;
    previewVersion = 0;
    previewExpanded = false;
    previewValidationRequested = false;
    pendingRemovalFocusIndex;

    renderedCallback() {
        if (this.pendingRemovalFocusIndex === undefined) {
            return;
        }
        const index = this.pendingRemovalFocusIndex;
        this.pendingRemovalFocusIndex = undefined;
        const button = this.isOnlyOneTime
            ? this.template.querySelector('[data-id="addTime"]')
            : this.template.querySelectorAll('[data-id="removeTime"]')[index];
        button.focusButton();
    }

    get timesWithDeleteLabels() {
        return this.times.map((time, index) => {
            const labelParts = [`Slett tidspunkt ${index + 1}`];
            if (time.date) {
                labelParts.push(`dato ${time.date.split('-').reverse().join('.')}`);
            }
            if (time.startTimeString) {
                labelParts.push(`starttid ${time.startTimeString}`);
            }
            if (time.endTimeString) {
                labelParts.push(`sluttid ${time.endTimeString}`);
            }
            return { ...time, deleteLabel: labelParts.join(', ') };
        });
    }

    get previewParameters() {
        const time = this.times[0];
        if (
            !this.isAdvancedTimes ||
            !time?.date ||
            !time.startTimeString ||
            !time.endTimeString ||
            !this.repeatingEndDateString ||
            time.endTime <= time.startTime ||
            (this.showWeekDays && !this.chosenDays.length) ||
            this.recurringDateError ||
            restrictTheNumberOfDays(this.repeatingEndDate, time.startTime)
        ) {
            return null;
        }
        return {
            startTime: time.startTime,
            endTime: time.endTime,
            recurringEndDate: this.repeatingEndDate,
            recurringType: this.repeatingOptionChosen,
            recurringDays: [...this.chosenDays]
        };
    }

    refreshRecurringPreview() {
        clearTimeout(this.previewTimer);
        if (this.previewValidationRequested) {
            this.template.querySelector('[data-id="recurringEndDate"]')?.sendErrorMessage('');
            this.previewValidationRequested = false;
        }
        const version = ++this.previewVersion;
        this.recurringPreview = undefined;
        this.previewError = '';
        this.previewExpanded = false;
        const parameters = this.previewParameters;
        this.previewLoading = !!parameters;
        if (!parameters) {
            return;
        }
        this.previewTimer = setTimeout(async () => {
            try {
                const result = await previewRecurringWorkOrders(parameters);
                if (version === this.previewVersion) {
                    this.recurringPreview = result;
                }
            } catch (error) {
                if (version === this.previewVersion) {
                    console.error('previewRecurringWorkOrders error', error);
                    this.previewError = error?.body?.message || 'Forhåndsvisningen kunne ikke hentes. Prøv igjen.';
                }
            } finally {
                if (version === this.previewVersion) {
                    this.previewLoading = false;
                    if (this.previewValidationRequested) {
                        this.template
                            .querySelector('[data-id="recurringEndDate"]')
                            ?.sendErrorMessage(this.previewValidationError);
                    }
                }
            }
        }, 300);
    }

    disconnectedCallback() {
        clearTimeout(this.previewTimer);
        this.previewVersion += 1;
    }

    get previewValidationError() {
        if (this.previewError) {
            return this.previewError;
        }
        if (this.previewLoading) {
            return 'Vent til forhåndsvisningen er klar.';
        }
        if (this.recurringPreview?.count === 0) {
            return 'Valgte gjentagelsesdager finnes ikke i perioden.';
        }
        return '';
    }

    get hasPreviewIntervals() {
        return this.recurringPreview?.count > 0;
    }

    get showPreviewTimeZoneNotice() {
        if (!this.hasPreviewIntervals) {
            return false;
        }
        const browserTimeZone = new Intl.DateTimeFormat().resolvedOptions().timeZone;
        const options = {
            year: 'numeric',
            month: '2-digit',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit',
            hourCycle: 'h23'
        };
        const browserFormatter = new Intl.DateTimeFormat('en-GB', { ...options, timeZone: browserTimeZone });
        const previewFormatter = new Intl.DateTimeFormat('en-GB', {
            ...options,
            timeZone: this.recurringPreview.timeZone
        });
        return this.recurringPreview.intervals.some((interval) =>
            [interval.startTime, interval.endTime].some(
                (time) => browserFormatter.format(new Date(time)) !== previewFormatter.format(new Date(time))
            )
        );
    }

    get previewToggleLabel() {
        if (this.recurringPreview?.count === 1) {
            return this.previewExpanded ? 'Skjul tidspunktet' : 'Vis tidspunktet';
        }
        return this.previewExpanded ? 'Skjul tidspunkter' : `Vis alle ${this.previewCountLabel}`;
    }

    get previewCountLabel() {
        const count = this.recurringPreview?.count;
        return `${count} ${count === 1 ? 'tidspunkt' : 'tidspunkter'}`;
    }

    get previewFirstDate() {
        return this.recurringPreview?.firstDate.split('-').reverse().join('.');
    }

    get previewLastDate() {
        return this.recurringPreview?.lastDate.split('-').reverse().join('.');
    }

    get previewIntervals() {
        if (!this.hasPreviewIntervals) {
            return [];
        }
        const weekdayFormatter = new Intl.DateTimeFormat('nb-NO', {
            weekday: 'long',
            timeZone: this.recurringPreview.timeZone
        });
        return this.recurringPreview.intervals.map((interval) => {
            const [startDate, startTime] = interval.startLabel.split(' ');
            const [endDate, endTime] = interval.endLabel.split(' ');
            return {
                startTime: interval.startTime,
                dateLabel: `${weekdayFormatter.format(new Date(interval.startTime))} ${startDate}`,
                startLabel: startTime,
                endLabel: startDate === endDate ? endTime : interval.endLabel
            };
        });
    }

    handlePreviewToggle(event) {
        this.previewExpanded = event.currentTarget.open;
    }

    setTimesValue(timeObject) {
        return {
            id: timeObject === null ? 0 : timeObject.id,
            date: timeObject === null ? null : timeObject.date,
            startTimeString: timeObject === null ? null : timeObject.startTimeString,
            endTimeString: timeObject === null ? null : timeObject.endTimeString,
            isNew: timeObject === null ? 1 : 0,
            dateMilliseconds: timeObject === null ? null : timeObject.dateMilliseconds,
            startTime: timeObject === null ? null : timeObject.startTime,
            endTime: timeObject === null ? null : timeObject.endTime
        };
    }

    getTimesIndex(name) {
        let j = -1;
        for (let i = 0; i < this.times.length; i++) {
            if (this.times[i].id === name) {
                j = i;
                break;
            }
        }
        return j;
    }

    // If there are more than 1 time entries in edit mode, hide the advanced time options
    get hideGjentagende() {
        return this.hideAdvancedTimesInEditMode === true;
    }

    /**
     * Shows date ordering errors as soon as both recurrence dates are selected.
     */
    get recurringDateError() {
        if (!this.isAdvancedTimes || !this.times[0]?.date || !this.repeatingEndDateString) {
            return '';
        }
        return (
            startDateBeforeRecurringEndDate(this.repeatingEndDate, this.times[0].startTime) ||
            restrictTheNumberOfDays(this.repeatingEndDate, this.times[0].startTime)
        );
    }

    get recurringBoundaryWarning() {
        if (
            !this.isAdvancedTimes ||
            !this.showWeekDays ||
            !this.times[0]?.date ||
            !this.repeatingEndDateString ||
            this.recurringDateError
        ) {
            return '';
        }

        const { firstDate, lastDate } = this.recurringPreview || {};
        if (!firstDate || !lastDate) {
            return '';
        }

        if (firstDate === this.times[0].date && lastDate === this.repeatingEndDateString) {
            return '';
        }

        return 'Datoene i serien er tilpasset ukedagene du har valgt.';
    }

    handleDateChange(event) {
        const index = this.getTimesIndex(event.target.name);
        this.times[index].date = event.detail;
        this.times[index].dateMilliseconds = new Date(event.detail).getTime();
        this.setStartTime(index);
        this.refreshRecurringPreview();
    }
    handleStartTimeChange(event) {
        const index = this.getTimesIndex(event.target.name);
        this.times[index].startTimeString = event.detail;
        this.times[index].startTime = this.timeStringToDateTime(
            this.times[index].dateMilliseconds,
            event.detail
        ).getTime();
        this.setEndTimeBasedOnStartTime(index);
        this.refreshRecurringPreview();
    }
    handleEndTimeChange(event) {
        const index = this.getTimesIndex(event.target.name);
        this.times[index].endTimeString = event.detail;
        this.times[index].endTime = this.timeStringToDateTime(
            this.times[index].dateMilliseconds +
                (this.times[index].endTimeString < this.times[index].startTimeString ? 86400000 : 0),
            event.detail
        ).getTime();
        this.refreshRecurringPreview();
    }
    setStartTime(index) {
        let dateTime = new Date();
        let timeString = this.dateTimeToTimeString(dateTime, false);

        if (this.times[index].startTimeString === null) {
            let combinedDateTime = this.combineDateTimes(this.times[index].dateMilliseconds, dateTime);
            this.times[index].startTime = combinedDateTime.getTime();

            this.times[index].startTimeString = timeString;
            let startTimeElements = this.template.querySelectorAll('[data-id="startTime"]');
            startTimeElements[index].setValue(this.times[index].startTimeString);
            this.setEndTimeBasedOnStartTime(index);
        } else {
            let startDateTime = this.timeStringToDateTime(
                this.times[index].dateMilliseconds,
                this.times[index].startTimeString
            );
            this.times[index].startTime = startDateTime.getTime();
            this.updateEndTimeBasedOnDate(index);
        }
    }
    setEndTimeBasedOnStartTime(index) {
        if (this.times[index].endTimeString === null || this.times[index].startTime > this.times[index].endTime) {
            let dateTime = new Date(this.times[index].startTime);
            dateTime.setHours(dateTime.getHours() + 1);
            let timeString = this.dateTimeToTimeString(dateTime, false);
            this.times[index].endTimeString = timeString;
            this.times[index].endTime = dateTime.getTime();
            let endTimeElements = this.template.querySelectorAll('[data-id="endTime"]');
            endTimeElements[index].setValue(this.times[index].endTimeString);
        }
    }

    updateEndTimeBasedOnDate(index) {
        let combinedDateTime = this.combineDateTimes(
            this.times[index].dateMilliseconds,
            new Date(this.times[index].endTime)
        );
        this.times[index].endTime = combinedDateTime.getTime();
    }

    dateTimeToTimeString(dateTime, isLoadingDatetimes) {
        let hours = dateTime.getHours();
        let minutes = isLoadingDatetimes ? dateTime.getMinutes() : 0;
        return (
            (hours < 10 ? '0' + hours.toString() : hours.toString()) +
            ':' +
            (minutes < 10 ? '0' + minutes.toString() : minutes.toString())
        );
    }
    timeStringToDateTime(dateTime, timeString) {
        let hoursMinutes = timeString.split(':');
        let hours = hoursMinutes[0].valueOf();
        let minutes = hoursMinutes[1].valueOf();
        dateTime = new Date(dateTime);
        dateTime.setHours(hours);
        dateTime.setMinutes(minutes);
        return dateTime;
    }
    combineDateTimes(date, time) {
        let dateTime = new Date(date);
        dateTime.setHours(time.getHours(), time.getMinutes(), 0, 0);
        return dateTime;
    }

    removeTime(event) {
        if (this.times.length > 1) {
            const index = this.getTimesIndex(event.target.name);
            if (index !== -1) {
                if (this.isEditMode && this.times[index].id === this.singleExistingWorkOrderId) {
                    const replacementIndex = index === 0 ? 1 : 0;
                    this.times[replacementIndex] = {
                        ...this.times[replacementIndex],
                        id: this.times[index].id,
                        isNew: 0
                    };
                }
                this.times.splice(index, 1);
                this.pendingRemovalFocusIndex = Math.min(index, this.times.length - 1);
            }
        }
        this.updateIsOnlyOneTime();
        this.refreshRecurringPreview();
    }
    addTime() {
        this.uniqueIdCounter += 1;
        let newTime = this.setTimesValue(null);
        newTime.id = this.uniqueIdCounter;
        this.times.push(newTime);
        this.updateIsOnlyOneTime();
    }
    updateIsOnlyOneTime() {
        this.isOnlyOneTime = this.times.length === 1;
    }

    @track timesBackup;
    advancedTimes(event) {
        this.isAdvancedTimes = event.detail;
        if (this.isAdvancedTimes) {
            this.timesBackup = this.times;
            this.times = [this.times[0]];
        } else {
            this.times = this.timesBackup;
        }
        this.updateIsOnlyOneTime();
        this.refreshRecurringPreview();
    }

    repeatingOptions = [
        { label: 'Hver dag', name: 'Daily', selected: true },
        { label: 'Hver uke', name: 'Weekly' },
        { label: 'Hver 2. Uke', name: 'Biweekly' },
        { label: 'Hver 4. Uke', name: 'Every4Weeks' }
    ];
    repeatingOptionChosen = 'Daily';
    @track isRepeating = true;
    @track showWeekDays = false;
    handleRepeatChoiceMade(event) {
        this.repeatingOptionChosen = event.detail.name;
        this.showWeekDays = event.detail.name !== 'Daily';
        this.isRepeating = true;
        this.repeatingOptions.forEach((element) => {
            if (element.name === event.detail.name) {
                element.selected = true;
            } else {
                element.selected = false;
            }
        });
        this.refreshRecurringPreview();
    }

    chosenDays = [];
    days = [
        { label: 'Mandag', value: false, name: 'monday' },
        { label: 'Tirsdag', value: false, name: 'tuesday' },
        { label: 'Onsdag', value: false, name: 'wednesday' },
        { label: 'Torsdag', value: false, name: 'thursday' },
        { label: 'Fredag', value: false, name: 'friday' },
        { label: 'Lørdag', value: false, name: 'saturday' },
        { label: 'Søndag', value: false, name: 'sunday' }
    ];

    handleDayChosen(event) {
        this.chosenDays = [];
        event.detail.forEach((element) => {
            if (element.checked) {
                this.chosenDays.push(element.name);
            }
        });
        this.refreshRecurringPreview();
    }
    @track repeatingEndDate;
    @track repeatingEndDateString;
    setRepeatingEndDateDate(event) {
        this.repeatingEndDateString = event.detail;
        this.repeatingEndDate = new Date(event.detail).getTime();
        this.refreshRecurringPreview();
    }

    @api
    getTimeInput() {
        let timeInputs = {};
        timeInputs.times = this.timesListToObject(this.times);
        timeInputs.repeatingOptionChosen = this.repeatingOptionChosen;
        timeInputs.chosenDays = this.chosenDays;
        timeInputs.repeatingEndDate = this.repeatingEndDate;
        timeInputs.isAdvancedTimes = this.isAdvancedTimes;
        return timeInputs;
    }

    @api
    validateFields() {
        let hasErrors = 0;
        hasErrors += this.validateSimpleTimes();
        if (this.isAdvancedTimes) {
            hasErrors += this.validateAdvancedTimes();
        }
        return hasErrors;
    }

    validateSimpleTimes() {
        let hasErrors = this.validateDate();
        hasErrors += this.validateStartTime();
        hasErrors += this.validateEndTime();
        return hasErrors;
    }
    validateDate() {
        let hasErrors = false;
        this.template.querySelectorAll('[data-id="date"]').forEach((element, index) => {
            let errorMessage = requireInput(element.value, 'Dato');
            if (errorMessage === '') {
                errorMessage = dateInPast(this.times[index].dateMilliseconds);
            }
            element.sendErrorMessage(errorMessage);
            hasErrors += errorMessage !== '';
        });
        return hasErrors;
    }
    validateStartTime() {
        let hasErrors = false;
        this.template.querySelectorAll('[data-id="startTime"]').forEach((element) => {
            let errorMessage = requireInput(element.getValue(), 'Starttid');
            element.sendErrorMessage(errorMessage);
            hasErrors += errorMessage !== '';
        });
        return hasErrors;
    }
    validateEndTime() {
        let errorMessage = '';
        let hasErrors = false;
        this.template.querySelectorAll('[data-id="endTime"]').forEach((element, index) => {
            errorMessage = requireInput(element.getValue(), 'Sluttid');
            if (errorMessage === '') {
                errorMessage = startBeforeEnd(this.times[index].endTime, this.times[index].startTime);
            }
            element.sendErrorMessage(errorMessage);
            hasErrors += errorMessage !== '';
        });
        return hasErrors;
    }
    validateAdvancedTimes() {
        let hasErrors = false;
        hasErrors += this.validateRecurringType();
        if (this.showWeekDays) {
            hasErrors += this.validateRecurringDays();
        }
        hasErrors += this.validateRecurringEndDate();
        return hasErrors;
    }
    validateRecurringType() {
        let hasErrors = false;
        //Default value is set, so no need to validate this field.
        return hasErrors;
    }
    validateRecurringDays() {
        let hasErrors = false;
        if (this.showWeekDays) {
            let element = this.template.querySelector('[data-id="recurringDays"]');
            let errorMessage = requireRecurringDays(element.getValue());
            element.sendErrorMessage(errorMessage);
            hasErrors += errorMessage !== '';
        }
        return hasErrors;
    }

    validateRecurringEndDate() {
        let hasErrors = false;
        let recurringEndDateElement = this.template.querySelector('[data-id="recurringEndDate"]');
        let errorMessage = requireInput(recurringEndDateElement.getValue(), 'Sluttdato');
        hasErrors += errorMessage !== '';
        if (errorMessage === '') {
            errorMessage = startDateBeforeRecurringEndDate(this.repeatingEndDate, this.times[0].startTime);
            hasErrors += errorMessage !== '';
        }
        if (errorMessage === '') {
            errorMessage = restrictTheNumberOfDays(this.repeatingEndDate, this.times[0].startTime);
            hasErrors += errorMessage !== '';
        }
        if (errorMessage === '' && this.previewParameters) {
            if (!this.recurringPreview && !this.previewLoading && !this.previewError) {
                this.refreshRecurringPreview();
            }
            errorMessage = this.previewValidationError;
            this.previewValidationRequested = true;
            hasErrors += errorMessage !== '';
        }
        recurringEndDateElement.sendErrorMessage(errorMessage);
        return hasErrors;
    }

    get dateTimeDesktopStyle() {
        let isDesktop = 'width: 100%;';
        if (window.screen.width > 576) {
            isDesktop = 'width: 30%;';
        }
        return isDesktop;
    }

    // Move up one level?
    @api requestIds = [];
    @wire(getTimes, { requestIds: '$requestIds', refreshToken: '$refreshToken' })
    wiredTimes(result) {
        this.singleExistingWorkOrderId = result.data?.length === 1 ? result.data[0].id : undefined;
        if (result.data) {
            if (result.data.length === 0) {
                this.times = [this.setTimesValue(null)];
            } else {
                this.times = []; // Empty times
                for (let timeMap of result.data) {
                    let timeObject = new Object(this.setTimesValue(timeMap));
                    timeObject.dateMilliseconds = new Date(timeMap.date).getTime();
                    timeObject.startTimeString = this.dateTimeToTimeString(new Date(Number(timeMap.startTime)), true);
                    timeObject.startTime = this.timeStringToDateTime(
                        timeObject.dateMilliseconds,
                        timeObject.startTimeString
                    ).getTime();
                    timeObject.endTimeString = this.dateTimeToTimeString(new Date(Number(timeMap.endTime)), true);
                    timeObject.endTime = this.timeStringToDateTime(
                        timeObject.dateMilliseconds +
                            (timeObject.endTimeString < timeObject.startTimeString ? 86400000 : 0),
                        timeObject.endTimeString
                    ).getTime();
                    this.times.push(timeObject);
                }
                this.validateSimpleTimes();
            }
            this.isOnlyOneTime = this.times.length === 1;
            this.refreshRecurringPreview();
        } else {
            this.times = [this.setTimesValue(null)];
        }
    }

    timesListToObject(list) {
        let times = {};
        for (let dateTime of list) {
            times[dateTime.id.toString()] = {
                startTime: dateTime.startTime,
                endTime: dateTime.endTime,
                isNew: dateTime.isNew
            };
        }
        return times;
    }
}
