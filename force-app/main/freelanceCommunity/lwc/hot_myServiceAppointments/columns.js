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
    },
    {
        name: 'IsUnreadMessage',
        label: 'Samtale',
        type: 'String',
        svg: true
    }
];

export let mobileColumns = [
    {
        label: 'Bestilt tid',
        name: 'startAndEndDateWeekday',
        type: 'String'
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
        label: 'Tolkemetode',
        name: 'HOT_WorkTypeName__c',
        type: 'String'
    },
    {
        label: 'Tema',
        name: 'Subject',
        type: 'String'
    },
    {
        label: 'Status',
        name: 'Status',
        type: 'String'
    },
    {
        name: 'IsUnreadMessage',
        label: 'Samtale',
        type: 'String',
        svg: true
    }
];
