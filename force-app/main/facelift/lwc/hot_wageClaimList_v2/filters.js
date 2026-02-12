export let filterArray = [
    {
        name: 'Status__c',
        label: 'Status',
        isCheckboxgroup: true,
        value: [
            {
                name: 'Åpen',
                label: 'Åpen'
            },
            {
                name: 'Tilbaketrukket tilgjengelighet',
                label: 'Tilbaketrukket tilgjengelighet'
            },
            {
                name: 'Dekket',
                label: 'Dekket'
            }
        ]
    },
    {
        name: 'timeInterval',
        label: 'Tidspunkt',
        isDateInterval: true,
        value: [
            {
                name: 'StartTime__c',
                label: 'Start dato',
                labelprefix: 'Fra: '
            },
            {
                name: 'EndTime__c',
                label: 'Slutt dato',
                labelprefix: 'Til: '
            }
        ]
    },
    {
        name: 'AssignmentType__c',
        label: 'Anledning',
        isCheckboxgroup: true,
        showMarkAllCheckbox: true,
        value: [
            {
                name: 'Dagligliv',
                label: 'Dagligliv'
            },
            {
                name: 'Arbeidsliv',
                label: 'Arbeidsliv'
            },
            {
                name: 'Helsetjenester',
                label: 'Helsetjenester'
            },
            {
                name: 'Utdanning',
                label: 'Utdanning'
            },
            {
                name: 'Tolk på arbeidsplass - TPA',
                label: 'Tolk på arbeidsplass - TPA'
            }
        ]
    }
];

export function defaultFilters() {
    return filterArray.map((filter) => ({
        ...filter,
        value: filter.value.map((v) => ({
            ...v,
            value: '',
            localTimeValue: ''
        }))
    }));
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
