import { LightningElement, track, wire, api } from 'lwc';
import getTimes from '@salesforce/apex/HOT_RequestListContoller.getTimes';
import {
    startDateValidations,
    endTimeValidations,
    recurringDaysValidations,
    recurringEndDateValidations
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
            startTime: timeObject === null ? null : timeObject.startTime,
            endTime: timeObject === null ? null : timeObject.endTime,
            isNew: timeObject === null ? 1 : 0,
            dateMilliseconds: timeObject === null ? null : timeObject.dateMilliseconds,
            startDateMilliseconds: timeObject === null ? null : timeObject.startDateMilliseconds,
            endDateMilliseconds: timeObject === null ? null : timeObject.endDateMilliseconds
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
        this.times[index].startTime = event.detail;
        this.times[index].startDateMilliseconds = this.timeStringToDateTime(
            this.times[index].dateMilliseconds,
            event.detail
        ).getTime();
        this.setEndTimeBasedOnStartTime(index);
    }
    handleEndTimeChange(event) {
        const index = this.getTimesIndex(event.target.name);
        this.times[index].endTime = event.detail;
        this.times[index].endDateMilliseconds = this.timeStringToDateTime(
            this.times[index].dateMilliseconds,
            event.detail
        );
    }
    setStartTime(index) {
        if (this.times[index].startTime === null) {
            let dateTime = new Date();
            let timeString = this.dateTimeToTimeString(dateTime);
            let combinedDateTime = this.combineDateTimes(this.times[index].dateMilliseconds, dateTime);
            this.times[index].startTime = timeString;
            this.times[index].startDateMilliseconds = combinedDateTime.getTime();
            let times = this.template.querySelectorAll('[data-id="startTime"]');
            times[index].setValue(this.times[index].startTime);
            this.setEndTimeBasedOnStartTime(index);
        }
    }
    setEndTimeBasedOnStartTime(index) {
        if (
            this.times[index].endTime === null ||
            this.times[index].startDateMilliseconds > this.times[index].endDateMilliseconds
        ) {
            let dateTime = new Date(this.times[index].startDateMilliseconds);
            dateTime.setHours(dateTime.getHours() + 1);
            let timeString = this.dateTimeToTimeString(dateTime);
            this.times[index].endTime = timeString;
            this.times[index].endDateMilliseconds = dateTime.getTime();
            let times = this.template.querySelectorAll('[data-id="endTime"]');
            times[index].setValue(this.times[index].endTime);
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
        { label: 'Hver dag', name: 'Daily' },
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
        timeInputs.times = this.times;
        timeInputs.repeatingOptionChosen = this.repeatingOptionChosen;
        timeInputs.chosenDays = this.chosenDays;
        timeInputs.repeatingEndDate = this.repeatingEndDate;
        timeInputs.isAdvancedTimes = this.isAdvancedTimes;
        return timeInputs;
    }

    @api
    validateFields() {
        /*let hasErrors = this.validateSimpleTimes();
        if (this.isAdvancedTimes) {
            hasErrors += this.validateAdvancedTimes();
        }*/
        let hasErrors = this.validateTimesAndDate();
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
        this.template.querySelectorAll('.date').forEach((element) => {
            hasErrors += validate(element, startDateValidations);
        });
        this.template.querySelectorAll('.start-tid').forEach((element) => {
            hasErrors += validate(element, startTimeValidations);
        });
        this.template.querySelectorAll('.slutt-tid').forEach((element) => {
            hasErrors += validate(element, endTimeValidations);
        });
        return hasErrors;
    }
    validateAdvancedTimes() {
        let hasErrors = false;
        let recurringTypeElement = this.template.querySelector('.recurringType');
        hasErrors += validate(recurringTypeElement.getElement(), recurringTypeValidations);
        if (this.showWeekDays) {
            let recurringDaysElement = this.template.querySelector('.recurringDays');
            hasErrors =
                hasErrors + validate(recurringDaysElement, recurringDaysValidations, this.repeatingOptionChosen);
        }
        let recurringEndDateElement = this.template.querySelector('.recurringEndDate');
        hasErrors =
            hasErrors +
            validate(
                recurringEndDateElement,
                recurringEndDateValidations,
                this.repeatingOptionChosen,
                this.times[0].date,
                this.chosenDays
            );
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
}
