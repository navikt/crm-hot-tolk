export let columns = [
    {
        label: 'Start tid',
        name: 'StartTime__c',
        type: 'Datetime',
    },
    {
        label: 'Slutt tid',
        name: 'EndTime__c',
        type: 'Datetime',
    },
    {
        label: 'Døv/Døvblind',
        name: 'DegreeOfHearingAndVisualImpairment__c',
        type: 'String',
    },
    {
        label: 'Oppdragstype',
        name: 'AssignmentType__c',
        type: 'String',
    },
    {
        label: 'Region',
        name: 'ServiceTerritoryName__c',
        type: 'String',
    },
    {
        label: 'Arbeidstype',
        name: 'WorkTypeName__c',
        type: 'String',
    },
    {
        label: 'Oppdrag',
        name: 'ServiceAppointmentName__c',
        type: 'String',
    },
    {
        label: 'Status',
        name: 'Status__c',
        type: 'String',
    },
];

export let mobileColumns = [
    {
        label: 'Start tid',
        name: 'StartTime__c',
        type: 'Datetime',
    },
    {
        label: 'Slutt tid',
        name: 'EndTime__c',
        type: 'Datetime',
    },
    {
        label: 'Region',
        name: 'ServiceTerritoryName__c',
        type: 'String',
    },
    {
        label: 'Oppdrag',
        name: 'ServiceAppointmentName__c',
        type: 'String',
    },
    {
        label: 'Status',
        name: 'Status__c',
        type: 'String',
    },
];