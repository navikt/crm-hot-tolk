export let filterArray = [
    {
        name: 'Status',
        label: 'Status',
        isCheckboxgroup: true,
        compare: equals,
        value: [
            {
                name: 'New',
                label: 'Ikke påbegynt',
                checked: true
            },
            {
                name: 'Canceled',
                label: 'Avlyst'
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
        value: []
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
    for (let val of this.value) {
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
