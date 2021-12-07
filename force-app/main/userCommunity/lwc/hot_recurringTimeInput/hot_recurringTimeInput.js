import { LightningElement, track, wire, api } from 'lwc';
import getTimes from '@salesforce/apex/HOT_RequestListContoller.getTimes';
import {
    dateInPast,
    startBeforeEnd,
    startDateBeforeRecurringEndDate,
    restrictTheNumberOfDays,
    chosenDaysWithinPeriod
} from './hot_recurringTimeInput_validationRules';

export default class Hot_recurringTimeInput extends LightningElement {
    @track times = [];
    @track isOnlyOneTime = true;
    @track isAdvancedTimes;
    uniqueIdCounter = 0;

    @api initialTimes = [];

    setTimesValue(timeObject) {
        return {
            id: timeObject === null ? 0 : timeObject.id,
            date: timeObject === null ? null : timeObject.date,
            startTimeString: timeObject === null ? null : timeObject.startTimeString,
            endTimeString: timeObject === null ? null : timeObject.endTimeString,
            isNew: timeObject === null ? 1 : 0,
            dateMilliseconds: timeObject === null ? null : timeObject.dateMilliseconds,
            startTime: timeObject === null ? null : timeObject.startTime,
            endDateMilliseconds: timeObject === null ? null : timeObject.endTime
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
        this.times[index].endTime = this.timeStringToDateTime(this.times[index].dateMilliseconds, event.detail);
    }
    setStartTime(index) {
        if (this.times[index].startTimeString === null) {
            let dateTime = new Date();
            let timeString = this.dateTimeToTimeString(dateTime);
            let combinedDateTime = this.combineDateTimes(this.times[index].dateMilliseconds, dateTime);
            this.times[index].startTimeString = timeString;
            this.times[index].startTime = combinedDateTime.getTime();
            let startTimeElements = this.template.querySelectorAll('[data-id="startTime"]');
            startTimeElements[index].setValue(this.times[index].startTimeString);
            this.setEndTimeBasedOnStartTime(index);
        }
    }
    setEndTimeBasedOnStartTime(index) {
        if (this.times[index].endTimeString === null || this.times[index].startTime > this.times[index].endTime) {
            let dateTime = new Date(this.times[index].startTime);
            dateTime.setHours(dateTime.getHours() + 1);
            let timeString = this.dateTimeToTimeString(dateTime);
            this.times[index].endTimeString = timeString;
            this.times[index].endTime = dateTime.getTime();
            let endTimeElements = this.template.querySelectorAll('[data-id="endTime"]');
            endTimeElements[index].setValue(this.times[index].endTimeString);
        }
    }
    dateTimeToTimeString(dateTime) {
        let hours = dateTime.getHours();
        return (hours < 10 ? '0' + hours.toString() : hours.toString()) + ':00';
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
    get days() {
        return [
            { label: 'Mandag', value: 'monday' },
            { label: 'Tirsdag', value: 'tuesday' },
            { label: 'Onsdag', value: 'wednesday' },
            { label: 'Torsdag', value: 'thursday' },
            { label: 'Fredag', value: 'friday' },
            { label: 'Lørdag', value: 'saturday' },
            { label: 'Søndag', value: 'sunday' }
        ];
    }
    handleDayChosen(event) {
        this.chosenDays = [];
        event.detail.forEach((element) => {
            if (element.checked) {
                this.chosenDays.push(element.value);
            }
        });
    }
    @track repeatingEndDate;
    setRepeatingEndDateDate(event) {
        this.repeatingEndDate = event.detail.value;
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
        if (this.isAdvancedTimes) {
            hasErrors += this.validateAdvancedTimes();
        }
        hasErrors += this.validateTimesAndDate();
        return hasErrors;
    }

    validateTimesAndDate() {
        let hasErrors = false;
        this.template.querySelectorAll('c-input').forEach((element) => {
            if (element.validationHandler()) {
                hasErrors += 1;
            }
        });
        return hasErrors;
    }
    validateSimpleTimes() {
        let hasErrors = false;
        this.template.querySelectorAll('[data-id="date"]').forEach((element, index) => {
            let errorMessage = dateInPast(this.times[index].dateMilliseconds);
            element.sendErrorMessage(errorMessage);
            if (errorMessage !== '') {
                hasErrors += 1;
            }
        });
        this.template.querySelectorAll('[data-id="endTime"]').forEach((element, index) => {
            let errorMessage = startBeforeEnd(this.times[index].endTime, this.times[index].startTime);
            element.sendErrorMessage(errorMessage);
            if (errorMessage !== '') {
                hasErrors += 1;
            }
        });
        return hasErrors;
    }
    validateAdvancedTimes() {
        let hasErrors = false;
        hasErrors += this.template.querySelector('[data-id="recurringType"]').validationHandler();

        if (this.showWeekDays) {
            hasErrors += this.template.querySelector('[data-id="recurringDays"]').validationHandler();
        }

        let recurringEndDateElement = this.template.querySelector('[data-id="recurringEndDate"]');

        let errorMessage = startDateBeforeRecurringEndDate(this.repeatingEndDate, this.times[0].startTime);
        recurringEndDateElement.sendErrorMessage(errorMessage);
        if (errorMessage !== '') {
            hasErrors += 1;
        }
        errorMessage = restrictTheNumberOfDays(this.repeatingEndDate, this.times[0].startTime);
        recurringEndDateElement.sendErrorMessage(errorMessage);
        if (errorMessage !== '') {
            hasErrors += 1;
        }
        errorMessage = chosenDaysWithinPeriod(
            this.repeatingOptionChosen,
            this.chosenDays,
            this.repeatingOptionChosen,
            this.chosenDays
        );
        recurringEndDateElement.sendErrorMessage(errorMessage);
        if (errorMessage !== '') {
            hasErrors += 1;
        }
        return hasErrors;
    }

    // -----------------------------------------
    get desktopstyle() {
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
                this.times = [];
                for (let timeMap of result.data) {
                    //let temp = new Object(this.setTimesValue(timeMap));
                    this.times.push(new Object(this.setTimesValue(timeMap)));
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
