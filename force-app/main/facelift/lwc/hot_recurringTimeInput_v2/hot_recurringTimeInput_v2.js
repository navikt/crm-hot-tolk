import { LightningElement, track, wire, api } from 'lwc';
import getTimes from '@salesforce/apex/HOT_RequestListController.getTimesNew';
import {
    requireInput,
    dateInPast,
    startBeforeEnd,
    requireRecurringDays,
    startDateBeforeRecurringEndDate,
    restrictTheNumberOfDays,
    chosenDaysWithinPeriod
} from './hot_recurringTimeInput_validationRules';

export default class hot_recurringTimeInput_v2 extends LightningElement {
    @track times = [];
    @track isOnlyOneTime = true;
    @track isAdvancedTimes;
    uniqueIdCounter = 0;

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

    handleDateChange(event) {
        const index = this.getTimesIndex(event.target.name);
        this.times[index].date = event.detail;
        this.times[index].dateMilliseconds = new Date(event.detail).getTime();
        this.setStartTime(index);
    }
    handleStartTimeChange(event) {
        const index = this.getTimesIndex(event.target.name);
        this.times[index].startTimeString = event.detail;
        this.times[index].startTime = this.timeStringToDateTime(
            this.times[index].dateMilliseconds,
            event.detail
        ).getTime();
        this.setEndTimeBasedOnStartTime(index);
    }
    handleEndTimeChange(event) {
        const index = this.getTimesIndex(event.target.name);
        this.times[index].endTimeString = event.detail;
        this.times[index].endTime = this.timeStringToDateTime(
            this.times[index].dateMilliseconds +
                (this.times[index].endTimeString < this.times[index].startTimeString ? 86400000 : 0),
            event.detail
        ).getTime();
    }
    setStartTime(index) {
        let dateTime = new Date();
        let timeString = this.dateTimeToTimeString(dateTime, false);
        let combinedDateTime = this.combineDateTimes(this.times[index].dateMilliseconds, dateTime);
        this.times[index].startTime = combinedDateTime.getTime();

        if (this.times[index].startTimeString === null) {
            this.times[index].startTimeString = timeString;
            let startTimeElements = this.template.querySelectorAll('[data-id="startTime"]');
            startTimeElements[index].setValue(this.times[index].startTimeString);
            this.setEndTimeBasedOnStartTime(index);
        } else {
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
        dateTime.setHours(time.getHours());
        return dateTime;
    }

    removeTime(event) {
        if (this.times.length > 1) {
            const index = this.getTimesIndex(event.target.name);
            if (index !== -1) {
                this.times.splice(index, 1);
            }
        }
        this.updateIsOnlyOneTime();
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
    }

    repeatingOptions = [
        { label: 'Hver dag', name: 'Daily', selected: true },
        { label: 'Hver uke', name: 'Weekly' },
        { label: 'Hver 2. Uke', name: 'Biweekly' }
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
    }
    @track repeatingEndDate;
    @track repeatingEndDateString;
    setRepeatingEndDateDate(event) {
        this.repeatingEndDateString = event.detail;
        this.repeatingEndDate = new Date(event.detail).getTime();
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
                errorMessage = startBeforeEnd(this.times[0].endTime, this.times[0].startTime);
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
        if (errorMessage === '') {
            errorMessage = chosenDaysWithinPeriod(
                this.repeatingOptionChosen,
                this.chosenDays,
                this.repeatingOptionChosen,
                this.chosenDays
            );
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
    @wire(getTimes, { requestIds: '$requestIds' })
    wiredTimes(result) {
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
