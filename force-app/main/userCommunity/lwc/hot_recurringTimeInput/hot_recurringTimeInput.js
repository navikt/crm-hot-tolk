import { LightningElement, track, wire, api } from 'lwc';
import getTimes from '@salesforce/apex/HOT_RequestListContoller.getTimes';

export default class Hot_recurringTimeInput extends LightningElement {
    @track isOnlyOneTime = true;
    @track times = [];
    @track uniqueIdCounter = 0;
    @track requestIds = [];

    wiredTimesValue;
    @wire(getTimes, { requestIds: '$requestIds' })
    wiredTimes(result) {
        this.wiredTimesValue = result.data;
        if (result.data) {
            if (result.data.length === 0) {
                this.times = [
                    {
                        id: 0,
                        date: null,
                        startTime: null,
                        endTime: null,
                        isNew: 1
                    }
                ];
            } else {
                //this.times = [...result.data];
                for (let timeMap of result.data) {
                    let temp = new Object({
                        id: timeMap.id,
                        date: timeMap.date,
                        startTime: timeMap.startTime,
                        endTime: timeMap.endTime,
                        isNew: 0
                    });
                    this.times.push(temp);
                }
                this.validateExistingDateTimes();
            }
            this.isOnlyOneTime = this.times.length === 1;
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            this.times = undefined;
        }
    }

    setDate(event) {
        let index = this.getIndexById(event.target.name);
        this.times[index].date = event.detail.value;
        let now = new Date();
        let tempTime = JSON.parse(JSON.stringify(now));
        tempTime = tempTime.split('');

        if (this.times[index].startTime === null || this.times[index].startTime === '') {
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

            this.times[index].startTime = tempTime.join('').substring(11, 16);
            first = parseFloat(tempTime[11]);
            second = parseFloat(tempTime[12]);
            second = (second + 1) % 10;
            if (second === 0) {
                first = first + 1;
            }
            tempTime[11] = first.toString();
            tempTime[12] = second.toString();
            this.times[index].endTime = tempTime.join('').substring(11, 16);
        }
        this.validateDateInput(event, index);
    }
    setStartTime(event) {
        let index = this.getIndexById(event.target.name);
        let tempTime = event.detail.value.split('');
        this.times[index].startTime = tempTime.join('').substring(0, 5);

        if (event.detail.value > this.times[index].endTime || this.times[index].endTime === null) {
            let first = parseFloat(tempTime[0]);
            let second = parseFloat(tempTime[1]);
            second = (second + 1) % 10;
            if (second === 0) {
                first = first + 1;
            }
            tempTime[0] = first.toString();
            tempTime[1] = second.toString();
            this.times[index].endTime = tempTime.join('').substring(0, 5);
        }
        this.validateDateInput(event, index);
    }

    setEndTime(event) {
        const index = this.getIndexById(event.target.name);
        this.times[index].endTime = event.detail.value.substring(0, 5);
    }

    updateValues(event, index) {
        let elements = event.target.parentElement.querySelector('.start-tid');
        elements.value = this.times[index].startTime;
        elements = event.target.parentElement.querySelector('.date');
        elements.value = this.times[index].date;
        elements = event.target.parentElement.querySelector('.slutt-tid');
        elements.value = this.times[index].endTime;
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

    addTime() {
        this.uniqueIdCounter += 1;
        let newTime = {
            id: this.uniqueIdCounter,
            date: null,
            startTime: null,
            endTime: null,
            isNew: 1
        };
        this.times.push(newTime);
        this.setIsOnlyOneTime();
    }
    setIsOnlyOneTime() {
        this.isOnlyOneTime = this.times.length === 1;
    }

    removeTime(event) {
        if (this.times.length > 1) {
            const index = this.getIndexById(event.target.name);
            if (index !== -1) {
                this.times.splice(index, 1);
            }
        }
        this.setIsOnlyOneTime();
    }

    @track isAdvancedTimes = false;
    @track timesBackup;
    advancedTimes(event) {
        this.isAdvancedTimes = event.detail.checked;
        if (this.isAdvancedTimes) {
            this.timesBackup = this.times;
            this.times = [this.times[0]];
        } else {
            this.times = this.timesBackup;
        }
        this.setIsOnlyOneTime();
    }
    @track isRepeating = false;
    @track showWeekDays = false;
    repeatingOptions = [
        { label: 'Hver dag', value: 'Daily' },
        { label: 'Hver uke', value: 'Weekly' },
        { label: 'Hver 2. Uke', value: 'Biweekly' }
    ];
    repeatingOptionChosen = '';
    handleRepeatChoiceMade(event) {
        this.repeatingOptionChosen = event.detail.value;
        if (event.detail.value === 'Weekly' || event.detail.value === 'Biweekly') {
            this.showWeekDays = true;
        } else {
            this.showWeekDays = false;
        }
        if (event.detail.value !== 'Never') {
            this.isRepeating = true;
        } else {
            this.isRepeating = false;
        }
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
        let recurringEndDateElement = this.template.querySelector('.recurringEndDate');
        validate(
            recurringEndDateElement,
            recurringEndDateValidations,
            this.repeatingOptionChosen,
            this.times[0].date,
            this.chosenDays
        );
    }

    @api
    handleAdvancedTimeValidations() {
        let typeElement = this.template.querySelector('.recurringType');
        let recurringTypeValid = validate(typeElement, recurringTypeValidations).length === 0;

        let daysElement = this.template.querySelector('.recurringDays');
        let recurringDaysValid =
            validate(daysElement, recurringDaysValidations, this.repeatingOptionChosen).length === 0;

        let recurringEndDateElement = this.template.querySelector('.recurringEndDate');
        let recurringEndDateValid =
            validate(
                recurringEndDateElement,
                recurringEndDateValidations,
                this.repeatingOptionChosen,
                this.times[0].date,
                this.chosenDays
            ).length === 0;

        return recurringTypeValid && recurringDaysValid && recurringEndDateValid;
    }

    handleDatetimeValidation() {
        let invalidIndex = [];
        for (let time of this.times) {
            if (!time.isValid) {
                invalidIndex.unshift(this.times.indexOf(time));
            }
        }
        if (invalidIndex.length !== 0) {
            let inputList = this.template.querySelectorAll('.dynamic-time-inputs-with-line_button');
            for (let index of invalidIndex) {
                let dateInputElement = inputList[index].querySelector('.date');
                this.throwInputValidationError(
                    dateInputElement,
                    dateInputElement.value ? 'Du kan ikke bestille tolk i fortiden.' : 'Fyll ut dette feltet.'
                );
            }
        }
        return invalidIndex;
    }

    validateExistingDateTimes() {
        for (let i = 0; i < this.times.length; i++) {
            let tempDate = this.formatDateTime(this.times[i]);
            tempDate = new Date(tempDate.date + ' ' + tempDate.startTime);
            this.times[i].isValid = this.validateDate(tempDate);
        }
    }
    validateDate(dateTime) {
        let nowTime = new Date();
        return dateTime.getTime() > nowTime.getTime();
    }

    validateDateInput(event, index) {
        let dateElement = event.target;
        let tempDate = this.formatDateTime(this.times[index]);
        tempDate = new Date(tempDate.date + ' ' + tempDate.startTime);
        if (!this.validateDate(tempDate)) {
            dateElement.setCustomValidity('Du kan ikke bestille tolk i fortiden.');
            dateElement.focus();
            this.times[index].isValid = false;
        } else {
            dateElement.setCustomValidity('');
            this.times[index].isValid = true;
        }
        dateElement.reportValidity();
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
}
