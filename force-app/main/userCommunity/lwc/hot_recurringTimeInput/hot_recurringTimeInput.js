import { LightningElement, track, wire, api } from 'lwc';
import getTimes from '@salesforce/apex/HOT_RequestListContoller.getTimes';
import { validate } from 'c/validationController';
import {
    startDateValidations,
    startTimeValidations,
    endTimeValidations,
    recurringTypeValidations,
    recurringDaysValidations,
    recurringEndDateValidations
} from './hot_recurringTimeInput_validationRules';

export default class Hot_recurringTimeInput extends LightningElement {
    @api requestIds = [];
    @track times = [];
    @track isOnlyOneTime = true;
    @api isEditMode = false;
    @track isAdvancedTimes;
    uniqueIdCounter = 0;

    setTimesValue(timeObject) {
        return {
            id: timeObject === null ? 0 : timeObject.id,
            date: timeObject === null ? null : timeObject.date,
            startTime: timeObject === null ? null : timeObject.startTime,
            endTime: timeObject === null ? null : timeObject.endTime,
            isNew: timeObject === null ? 1 : 0
        };
    }

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

    // Auto fill methods
    setDate(event) {
        let index = this.getIndexById(event.target.name);
        this.times[index].date = event.detail.value;

        if (this.times[index].startTime === null || this.times[index].startTime === '') {
            let tempTime = this.getNextHour();
            this.times[index].startTime = tempTime.substring(11, 16);

            tempTime = this.addOneHour(tempTime);
            this.times[index].endTime = tempTime.substring(11, 16);
        }
    }
    setStartTime(event) {
        let index = this.getIndexById(event.target.name);
        this.times[index].startTime = event.detail.value.substring(0, 5);

        if (event.detail.value > this.times[index].endTime || this.times[index].endTime === null) {
            let tempTime = this.addOneHour(event.detail.value);
            this.times[index].endTime = tempTime.substring(0, 5);
        }
    }
    setEndTime(event) {
        const index = this.getIndexById(event.target.name);
        this.times[index].endTime = event.detail.value.substring(0, 5);
    }

    getNextHour() {
        let now = new Date();
        let tempTime = JSON.parse(JSON.stringify(now));
        tempTime = tempTime.split('');
        if (Math.abs(parseFloat(tempTime[14] + tempTime[15]) - now.getMinutes()) <= 1) {
            tempTime[14] = '0';
            tempTime[15] = '0';
        }

        let first = parseFloat(tempTime[11]);
        let second = parseFloat(tempTime[12]);
        second = (second + 2) % 10;
        if (second === 0 || second === 1) {
            first = first + 1;
        }
        tempTime[11] = first.toString();
        tempTime[12] = second.toString();
        return tempTime.join('');
    }
    addOneHour(input) {
        input = input.split('');
        let first = parseFloat(input[11]);
        let second = parseFloat(input[12]);
        second = (second + 1) % 10;
        if (second === 0) {
            first = first + 1;
        }
        input[11] = first.toString();
        input[12] = second.toString();
        return input.join('');
    }

    getIndexById(id) {
        let j = -1;
        for (let i = 0; i < this.times.length; i++) {
            if (this.times[i].id === id) {
                j = i;
            }
        }
        return j;
    }
    removeTime(event) {
        if (this.times.length > 1) {
            const index = this.getIndexById(event.target.name);
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

    //Advanced Time functions
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
        this.chosenDays = event.detail.value;
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
    timesListToObject(list) {
        let times = {};
        for (let dateTime of list) {
            dateTime = this.formatDateTime(dateTime);
            times[dateTime.id.toString()] = {
                startTime: new Date(dateTime.date + ' ' + dateTime.startTime).getTime(),
                endTime:
                    dateTime.startTime < dateTime.endTime
                        ? new Date(dateTime.date + ' ' + dateTime.endTime).getTime()
                        : new Date(dateTime.date + ' ' + dateTime.endTime).getTime() + 24 * 60 * 60 * 1000,
                isNew: dateTime.isNew
            };
        }
        return times;
    }
    formatDateTime(dateTime) {
        const year = dateTime.date.substring(0, 4);
        const month = dateTime.date.substring(5, 7);
        const day = dateTime.date.substring(8, 10);

        const startHour = dateTime.startTime.substring(0, 2);
        const startMinute = dateTime.startTime.substring(3, 5);
        const endHour = dateTime.endTime.substring(0, 2);
        const endMinute = dateTime.endTime.substring(3, 5);

        const newDateTime = {};
        newDateTime.id = dateTime.id;
        newDateTime.date = month + '/' + day + '/' + year;
        newDateTime.startTime = startHour + ':' + startMinute;
        newDateTime.endTime = endHour + ':' + endMinute;
        newDateTime.isValid = dateTime.isValid;
        newDateTime.isNew = dateTime.isNew;

        return newDateTime;
    }

    attemptedSubmit = false;
    @api
    validateFields() {
        this.attemptedSubmit = true;
        let hasErrors = this.validateSimpleTimes();
        if (this.isAdvancedTimes) {
            hasErrors += this.validateAdvancedTimes();
        }
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
}
