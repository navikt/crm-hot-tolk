export let columns = [
    {
        label: 'Tid',
        name: 'StartAndEndDate',
        type: 'Datetime'
    },
    {
        label: 'Dag',
        name: 'weekday',
        type: 'String'
    },
    {
        label: 'Informasjon',
        name: 'HOT_Information__c',
        type: 'String'
    },
    {
        label: 'Tema',
        name: 'HOT_FreelanceSubject__c',
        type: 'String'
    },
    {
        label: 'Merknad',
        name: 'isUrgent',
        type: 'boolean',
        svg: true
    }
];
export let inDetailsColumns = [
    {
        label: 'Tid',
        name: 'StartAndEndDate',
        type: 'Datetime'
    },
    {
        label: 'Informasjon',
        name: 'HOT_Information__c',
        type: 'String'
    },
    {
        label: 'Tema',
        name: 'HOT_FreelanceSubject__c',
        type: 'String'
    }
];

export let mobileColumns = [
    {
        label: 'Tid',
        name: 'startAndEndDateWeekday',
        type: 'String',
        bold: true
    },
    {
        label: 'Dag',
        name: 'weekday',
        type: 'String'
    },
    {
        label: '',
        name: 'isUrgent',
        type: 'boolean',
        svg: true
    },
    {
        label: 'Info',
        name: 'HOT_Information__c',
        type: 'String'
    },

    {
        label: 'Tema',
        name: 'HOT_FreelanceSubject__c',
        type: 'String'
    }
];
