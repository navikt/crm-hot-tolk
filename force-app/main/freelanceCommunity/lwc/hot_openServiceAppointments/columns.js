export let columns = [
    {
        label: 'Tid',
        name: 'StartAndEndDate',
        type: 'Datetime'
    },
    {
        label: 'Dag',
        name: 'dag',
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
        label: '',
        name: 'haster',
        type: 'boolean',
        svg: true
    }
];

export let mobileColumns = [
    {
        label: 'Tid',
        name: 'StartAndEndDate',
        type: 'Datetime'
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
        label: '',
        name: 'akutt',
        type: 'boolean',
        svg: true
    }
];
