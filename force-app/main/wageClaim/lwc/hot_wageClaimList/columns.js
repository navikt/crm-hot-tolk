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
        label: 'Oppdragsnummer',
        name: 'ServiceAppointmentName__c',
        type: 'String'
    },
    {
        label: 'Oppdragstype',
        name: 'AssignmentType__c',
        type: 'String'
    },
    {
        label: 'Tolkemetode',
        name: 'WorkTypeName__c',
        type: 'String'
    },
    {
        label: 'Status',
        name: 'Status__c',
        type: 'String'
    }
];

export let mobileColumns = [
    {
        label: 'Tid',
        name: 'StartAndEndDate',
        type: 'Datetime'
    },
    {
        label: 'Region',
        name: 'ServiceTerritoryName__c',
        type: 'String'
    },
    {
        label: 'Oppdrag',
        name: 'ServiceAppointmentName__c',
        type: 'String'
    },
    {
        label: 'Status',
        name: 'Status__c',
        type: 'String'
    }
];
