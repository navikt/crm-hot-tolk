export let filterArray = [
    {
        name: 'status',
        label: 'Status',
        isCheckboxgroup: true,
        value: [
            {
                name: 'open',
                label: 'Ikke påbegynt',
                value: true
            },
            {
                name: 'underTreatment',
                label: 'Under behandling'
            }
        ]
    },
    {
        name: 'timeInterval',
        label: 'Tidspunkt',
        isDateInterval: true,
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
        value: []
    }
];

export function defaultFilters() {
    let nowDate = new Date();
    filterArray[1].value[0].value = nowDate.toISOString().split('T')[0];
    return filterArray;
}
