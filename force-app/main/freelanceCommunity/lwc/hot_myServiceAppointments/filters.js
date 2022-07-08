export let filterArray = [
    {
        name: 'Status',
        label: 'Status',
        isCheckboxgroup: true,
        value: [
            {
                name: 'Tildelt',
                label: 'Tildelt'
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
                name: 'EarliestStartTime',
                label: 'Start dato',
                labelprefix: 'Fra: '
            },
            {
                name: 'DueDate',
                label: 'Slutt dato',
                labelprefix: 'Til: '
            }
        ]
    },
    {
        name: 'HOT_WorkTypeName__c',
        label: 'Tolkemetode',
        isCheckboxgroup: true,
        showMarkAllCheckbox: true,
        value: [
            {
                name: 'TS - Tegnspråk',
                label: 'TS - Tegnspråk'
            },
            {
                name: 'SK - Skrivetolking',
                label: 'SK - Skrivetolking'
            },
            {
                name: 'TSS - Tegn Som Støtte Til Munnavlesning',
                label: 'TSS - Tegn Som Støtte Til Munnavlesning'
            },
            {
                name: 'TSBS - Tegnspråk I Begrenset Synsfelt',
                label: 'TSBS - Tegnspråk I Begrenset Synsfelt'
            },
            {
                name: 'TT - Taletolking',
                label: 'TT - Taletolking'
            },
            {
                name: 'TTS - Taktilt Tegnspråk',
                label: 'TTS - Taktilt Tegnspråk'
            }
        ]
    },
    {
        name: 'HOT_AssignmentType__c',
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
    },
    {
        name: 'HOT_ServiceTerritoryDeveloperName__c',
        label: 'Region',
        isCheckboxgroup: true,
        showMarkAllCheckbox: true,
        value: [
            {
                name: 'Agder',
                label: 'Agder'
            },
            {
                name: 'Innlandet',
                label: 'Innlandet'
            },
            {
                name: 'More_og_Romsdal',
                label: 'Møre og Romsdal'
            },
            {
                name: 'Nordland',
                label: 'Nordland'
            },
            {
                name: 'Oslo',
                label: 'Oslo'
            },
            {
                name: 'Rogaland',
                label: 'Rogaland'
            },
            {
                name: 'Tromso',
                label: 'Troms og Finnmark'
            },
            {
                name: 'Trondelag',
                label: 'Trøndelag'
            },
            {
                name: 'Vestfold_og_Telemark',
                label: 'Vestfold og Telemark'
            },
            {
                name: 'Vestland',
                label: 'Vestland'
            },
            {
                name: 'Vest_Viken',
                label: 'Vest-Viken'
            },
            {
                name: 'Ost_Viken',
                label: 'Øst-Viken'
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
