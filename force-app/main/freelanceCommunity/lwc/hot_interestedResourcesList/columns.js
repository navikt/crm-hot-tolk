export let columns = [
    {
        label: 'Start tid',
        name: 'ServiceAppointmentStartTime__c',
        type: 'Datetime',
    },
    {
        label: 'Slutt tid',
        name: 'ServiceAppointmentEndTime__c',
        type: 'Datetime',
    },
    {
        label: 'Poststed',
        name: 'ServiceAppointmentCity__c',
        type: 'String',
    },
    {
        label: 'Tolkemetode',
        name: 'WorkTypeName__c',
        type: 'String',
    },
    {
        label: 'Tema',
        name: 'ServiceAppointmentFreelanceSubject__c',
        type: 'String',
    },
    {
        label: 'Status',
        name: 'Status__c',
        type: 'String',
    },
    {
        label: 'Ny kommentar',
        name: 'IsNewComment__c',
        type: 'boolean'
    },
];

export let mobileColumns = [
    {
        label: 'Start tid',
        name: 'ServiceAppointmentStartTime__c',
        type: 'Datetime',
    },
    {
        label: 'Slutt tid',
        name: 'ServiceAppointmentEndTime__c',
        type: 'Datetime',
    },
    {
        label: 'Tolkemetode',
        name: 'WorkTypeName__c',
        type: 'String',
    },
    {
        label: 'Tema',
        name: 'ServiceAppointmentFreelanceSubject__c',
        type: 'String',
    },
];