export let filterArray = [
    {
        name: 'Status',
        label: 'Status',
        isCheckboxgroup: true,
        compare: equals,
        value: [
            {
                name: 'New',
                label: 'Ikke påbegynt'
            },
            {
                name: 'Canceled',
                label: 'Avlyst'
            },
            {
                name: 'Dispatched',
                label: 'Du har fått tolk'
            },
            {
                name: 'In Progress',
                label: 'Pågår'
            },
            {
                name: 'Cannot Complete',
                label: 'Ikke ledig tolk'
            },
            {
                name: 'Completed',
                label: 'Ferdig'
            }
        ]
    },
    {
        name: 'timeInterval',
        label: 'Tidspunkt',
        isDateInterval: true,
        compare: dateBetween,
        value: [
            {
                name: 'StartDate',
                label: 'Start dato',
                labelprefix: 'Fra: '
            },
            {
                name: 'EndDate',
                label: 'Slutt dato',
                labelprefix: 'Til: '
            }
        ]
    },
    {
        name: 'AssignmentType__c',
        label: 'Anledning',
        isCheckboxgroup: true,
        compare: equals,
        value: [
            {
                name: 'Private',
                label: 'Dagligliv'
            },
            {
                name: 'Work',
                label: 'Arbeidsliv'
            },
            {
                name: 'Health Services',
                label: 'Helsetjenester'
            },
            {
                name: 'Education',
                label: 'Utdanning'
            },
            {
                name: 'Interpreter at Work',
                label: 'Tolk på arbeidsplass - TPA'
            }
        ]
    }
];

export function defaultFilters() {
    filterArray[1].value[0].value = new Date().toISOString().split('T')[0];
    let localTimeValue = filterArray[1].value[0].localTimeValue;
    localTimeValue = new Date().toLocaleString();
    filterArray[1].value[0].localTimeValue = localTimeValue.substring(0, localTimeValue.length - 10);
    return filterArray;
}

function equals(record) {
    console.log('record: ', JSON.stringify(record));
    for (let val of this.value) {
        console.log('val.value: ', val.value);
        console.log('val.name: ', val.name);
        console.log('this.name: ', this.name);
        console.log('record[this.name]: ', record[this.name]);
        if (val.value === true && record[this.name] !== val.name) {
            return false;
        }
    }
    return true;
}

function dateBetween(record) {
    let startVal = this.value[0];
    let endVal = this.value[1];
    if (startVal.value !== undefined && startVal.value !== false) {
        let recordStartDate = new Date(record[startVal.name]);
        let startDate = new Date(startVal.value);
        startDate.setHours(0);
        startDate.setMinutes(0);
        if (recordStartDate < startDate) {
            return false;
        }
    }
    if (endVal.value !== undefined && endVal.value !== false) {
        let recordEndDate = new Date(record[endVal.name]);
        recordEndDate.setHours(0);
        recordEndDate.setMinutes(0);
        let endDate = new Date(endVal.value);
        if (recordEndDate > endDate) {
            return false;
        }
    }
    return true;
}
