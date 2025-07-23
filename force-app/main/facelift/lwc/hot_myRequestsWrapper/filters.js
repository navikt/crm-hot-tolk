export let filterArray = [
    {
        name: 'HOT_ExternalWorkOrderStatus__c',
        label: 'Status',
        isCheckboxgroup: true,
        value: [
            {
                name: 'All records',
                label: ''
            },
            {
                name: 'Åpen',
                label: 'Åpen'
            },
            {
                name: 'Under behandling',
                label: 'Under behandling'
            },
            {
                name: 'Avlyst',
                label: 'Avlyst'
            },
            {
                name: 'Du har fått tolk',
                label: 'Du har fått tolk'
            },
            {
                name: 'Ikke ledig tolk',
                label: 'Ikke ledig tolk'
            },
            {
                name: 'Ferdig',
                label: 'Ferdig'
            }
        ]
    },
    {
        name: 'timeInterval',
        label: 'Tidspunkt',
        isDateInterval: true,
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
        name: 'HOT_AssignmentType__c',
        label: 'Anledning',
        isCheckboxgroup: true,
        value: [
            {
                name: 'All records',
                label: ''
            },
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

export function compare(filter, record) {
    if (filter.isDateInterval) {
        return dateBetween(filter, record);
    }
    return equals(filter, record);
}

function equals(filter, record) {
    let toInclude = true;
    for (let val of filter.value) {
        if (val.value) {
            if (record[filter.name] === val.name) {
                return true;
            }
            toInclude = false;
        }
    }
    return toInclude;
}

function dateBetween(filter, record) {
    let startVal = filter.value[0];
    let endVal = filter.value[1];
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
