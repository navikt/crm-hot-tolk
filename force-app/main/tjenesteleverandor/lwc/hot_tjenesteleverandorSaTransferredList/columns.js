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
        label: 'Overført dato',
        name: 'HOT_TjenesteleverandorTransferDate__c',
        type: 'Datetime'
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
        label: 'Info',
        name: 'HOT_Information__c',
        type: 'String'
    },
    {
        label: 'Tema',
        name: 'HOT_FreelanceSubject__c',
        type: 'String'
    },
    {
        label: 'Overført dato',
        name: 'HOT_TjenesteleverandorTransferDate__c',
        type: 'Datetime'
    }
];
