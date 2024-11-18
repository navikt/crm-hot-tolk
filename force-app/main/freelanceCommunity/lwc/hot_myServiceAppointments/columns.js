export let columns = [
    {
        label: 'Bestilt tid',
        name: 'StartAndEndDate',
        type: 'Datetime'
    },
    {
        label: 'Oppdragsnummer',
        name: 'AppointmentNumber',
        type: 'String'
    },
    {
        label: 'Poststed',
        name: 'City',
        type: 'String'
    },
    {
        label: 'Tema',
        name: 'Subject',
        type: 'String'
    },
    {
        label: 'Tolkemetode',
        name: 'HOT_WorkTypeName__c',
        type: 'String'
    },
    {
        label: 'Status',
        name: 'Status',
        type: 'String'
    }
];

export let mobileColumns = [
    {
        label: 'Oppdragsnummer',
        name: 'AppointmentNumber',
        type: 'String'
    },
    {
        label: 'Bestilt tid',
        name: 'startAndEndDateWeekday',
        type: 'String'
    },
    {
        label: 'Poststed',
        name: 'City',
        type: 'String'
    },
    // {
    //     label: 'Tolkemetode',
    //     name: 'HOT_WorkTypeName__c',
    //     type: 'String'
    // },
    {
        label: 'Tema',
        name: 'Subject',
        type: 'String'
    }
];
