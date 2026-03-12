export let columns = [
    {
        label: 'Tid',
        name: 'StartAndEndDate',
        type: 'Datetime'
    },
    {
        label: 'Oppdrag',
        name: 'ServiceAppointmentName__c',
        type: 'String'
    },
    {
        label: 'Årsak',
        name: 'Reason__c',
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
        label: 'Tid',
        name: 'StartAndEndDate',
        type: 'Datetime'
    },
    {
        label: 'Oppdrag',
        name: 'ServiceAppointmentName__c',
        type: 'String'
    },
    {
        label: 'Årsak',
        name: 'Reason__c',
        type: 'String',
        showMobileLabel: true
    },
    {
        name: 'IsUnreadMessage',
        label: 'Samtale',
        type: 'String',
        svg: true
    }
];
