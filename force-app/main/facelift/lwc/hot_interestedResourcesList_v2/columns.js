export let columns = [
    {
        label: 'Tid',
        name: 'StartAndEndDate',
        type: 'Datetime'
    },
    {
        label: 'Poststed',
        name: 'ServiceAppointmentCity__c',
        type: 'String'
    },
    {
        label: 'Tolkemetode',
        name: 'WorkTypeName__c',
        type: 'String'
    },
    {
        label: 'Tema',
        name: 'ServiceAppointmentFreelanceSubject__c',
        type: 'String'
    },
    {
        label: 'Status',
        name: 'Status__c',
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
        name: 'startAndEndDateWeekday',
        type: 'String'
    },
    {
        label: 'Status',
        name: 'Status__c',
        type: 'String'
    },
    {
        label: 'Tolkemetode',
        name: 'WorkTypeName__c',
        type: 'String'
    },
    {
        label: 'Poststed',
        name: 'ServiceAppointmentCity__c',
        type: 'String'
    },
    {
        label: 'Tema',
        name: 'ServiceAppointmentFreelanceSubject__c',
        type: 'String'
    },
    {
        name: 'IsUnreadMessage',
        label: '',
        type: 'String',
        svg: true
    }
];

export let iconByValue = {
    true: {
        icon: 'Information',
        fill: '',
        ariaLabel: 'Ulest melding'
    },
    false: {
        icon: 'SuccessFilled',
        fill: 'Green',
        ariaLabel: 'Ingen nye meldinger'
    },
    noThread: {
        icon: '',
        fill: '',
        ariaLabel: ''
    }
};
