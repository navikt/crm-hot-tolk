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
        label: 'Ny kommentar',
        name: 'IsNewComment__c',
        type: 'boolean'
    }
];

export let mobileColumns = [
    {
        label: 'Tid',
        name: 'StartAndEndDate',
        type: 'Datetime'
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
    }
];
