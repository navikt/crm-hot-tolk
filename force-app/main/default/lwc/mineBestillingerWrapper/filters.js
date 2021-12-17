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
                value: true
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
        compare: between,
        value: [
            {
                name: 'startDate',
                label: 'Start dato'
            },
            {
                name: 'endDate',
                label: 'Slutt dato'
            }
        ]
    },
    {
        name: 'setting',
        label: 'Anledning',
        isCheckboxgroup: true,
        compare: equals,
        value: []
    }
];

export function defaultFilters() {
    let nowDate = new Date();
    filterArray[1].value[0].value = nowDate.toISOString().split('T')[0];
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

function between(record) {
    return true;
}
