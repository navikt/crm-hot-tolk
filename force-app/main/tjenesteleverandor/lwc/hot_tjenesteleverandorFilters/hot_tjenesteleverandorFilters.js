const FILTER_DEFINITIONS = [
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
            { name: 'TS - Tegnspråk', label: 'TS - Tegnspråk' },
            { name: 'SK - Skrivetolking', label: 'SK - Skrivetolking' },
            {
                name: 'TSS - Tegn Som Støtte Til Munnavlesning',
                label: 'TSS - Tegn Som Støtte Til Munnavlesning'
            },
            {
                name: 'TSBS - Tegnspråk I Begrenset Synsfelt',
                label: 'TSBS - Tegnspråk I Begrenset Synsfelt'
            },
            { name: 'TT - Taletolking', label: 'TT - Taletolking' },
            { name: 'TTS - Taktilt Tegnspråk', label: 'TTS - Taktilt Tegnspråk' }
        ]
    },
    {
        name: 'HOT_AssignmentType__c',
        label: 'Anledning',
        isCheckboxgroup: true,
        showMarkAllCheckbox: true,
        value: [
            { name: 'Dagligliv', label: 'Dagligliv' },
            { name: 'Arbeidsliv', label: 'Arbeidsliv' },
            { name: 'Helsetjenester', label: 'Helsetjenester' },
            { name: 'Utdanning', label: 'Utdanning' },
            { name: 'Tolk på arbeidsplass - TPA', label: 'Tolk på arbeidsplass - TPA' }
        ]
    },
    {
        name: 'HOT_ServiceTerritoryDeveloperName__c',
        label: 'Region',
        isCheckboxgroup: true,
        showMarkAllCheckbox: true,
        value: [
            { name: 'Agder', label: 'Agder' },
            { name: 'Innlandet', label: 'Innlandet' },
            { name: 'More_og_Romsdal', label: 'Møre og Romsdal' },
            { name: 'Nordland', label: 'Nordland' },
            { name: 'Oslo', label: 'Oslo' },
            { name: 'Rogaland', label: 'Rogaland' },
            { name: 'Tromso', label: 'Troms og Finnmark' },
            { name: 'Trondelag', label: 'Trøndelag' },
            { name: 'Vestfold_og_Telemark', label: 'Vestfold og Telemark' },
            { name: 'Vestland', label: 'Vestland' },
            { name: 'Vest_Viken', label: 'Vest-Viken' },
            { name: 'Ost_Viken', label: 'Øst-Viken' }
        ]
    },
    {
        name: 'Search',
        label: 'Søk',
        isSearch: true,
        value: [
            { name: 'HOT_FreelanceSubject__c' },
            { name: 'HOT_ServiceAppointmentNumber__c' },
            { name: 'StartAndEndDate' },
            { name: 'HOT_AddressFormated__c' },
            { name: 'HOT_WorkTypeName__c' },
            { name: 'HOT_ServiceTerritoryName__c' },
            { name: 'HOT_AssignmentType__c' },
            { name: 'HOT_Information__c' }
        ]
    }
];

export function createDefaultFilters() {
    return JSON.parse(JSON.stringify(FILTER_DEFINITIONS));
}

export function restoreFilters(storageKey) {
    const storedFilters = sessionStorage.getItem(storageKey);
    if (!storedFilters) {
        return createDefaultFilters();
    }

    try {
        const filters = JSON.parse(storedFilters);
        return Array.isArray(filters) && filters.length === FILTER_DEFINITIONS.length
            ? filters
            : createDefaultFilters();
    } catch {
        sessionStorage.removeItem(storageKey);
        return createDefaultFilters();
    }
}

export function filterRecords(records, filters) {
    return records.filter((record) => filters.every((filter) => compare(filter, record)));
}

function compare(filter, record) {
    if (filter.isDateInterval) {
        return dateBetween(filter, record);
    }
    if (filter.isSearch) {
        return searchRecord(filter, record);
    }
    return equals(filter, record);
}

function equals(filter, record) {
    const selectedValues = filter.value.filter((value) => value.value);
    return selectedValues.length === 0 || selectedValues.some((value) => record[filter.name] === value.name);
}

function dateBetween(filter, record) {
    const startValue = filter.value[0];
    const endValue = filter.value[1];

    if (startValue?.value) {
        const recordStartDate = new Date(record[startValue.name]);
        const startDate = new Date(startValue.value);
        startDate.setHours(0, 0, 0, 0);
        if (recordStartDate < startDate) {
            return false;
        }
    }

    if (endValue?.value) {
        const recordEndDate = new Date(record[endValue.name]);
        const endDate = new Date(endValue.value);
        endDate.setHours(23, 59, 59, 999);
        if (recordEndDate > endDate) {
            return false;
        }
    }

    return true;
}

function searchRecord(filter, record) {
    const searchTerm = filter.searchTerm?.trim().toLowerCase();
    if (!searchTerm) {
        return true;
    }

    return filter.value.some((field) =>
        String(record[field.name] ?? '')
            .toLowerCase()
            .includes(searchTerm)
    );
}
