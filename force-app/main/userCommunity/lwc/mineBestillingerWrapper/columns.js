export let workOrderColumns = [
    {
        name: 'StartAndEndDate',
        label: 'Tid',
        type: 'Datetime'
    },
    {
        name: 'HOT_ExternalWorkOrderStatus__c',
        label: 'Status',
        type: 'String',
        svg: true
    },
    {
        name: 'HOT_AddressFormated__c',
        label: 'Adresse',
        type: 'String'
    },
    {
        name: 'HOT_Interpreters__c',
        label: 'Tolk',
        type: 'String'
    }
];

export let workOrderMobileColumns = [
    {
        name: 'StartAndEndDate',
        label: 'Tid',
        type: 'Datetime'
    },
    {
        name: 'HOT_ExternalWorkOrderStatus__c',
        label: 'Status',
        type: 'String',
        svg: true
    },
    {
        name: 'HOT_Interpreters__c',
        label: 'Tolk',
        type: 'String'
    }
];

export let columns = [
    {
        name: 'StartAndEndDate',
        label: 'Tid',
        type: 'Datetime'
    },
    {
        name: 'HOT_ExternalWorkOrderStatus__c',
        label: 'Status',
        type: 'String',
        svg: true
    },
    {
        name: 'Subject',
        label: 'Tema',
        type: 'String'
    },
    {
        name: 'HOT_AddressFormated__c',
        label: 'Adresse',
        type: 'String'
    }
];

export let mobileColumns = [
    {
        name: 'StartAndEndDate',
        label: 'Tid',
        type: 'Datetime'
    },
    {
        name: 'HOT_ExternalWorkOrderStatus__c',
        label: 'Status',
        type: 'String',
        svg: true
    },
    {
        name: 'Subject',
        label: 'Tema',
        type: 'String'
    }
];

export let iconByValue = {
    'Du har fått tolk': {
        icon: 'SuccessFilled',
        fill: 'Green',
        ariaLabel: 'Du har fått tolk'
    },
    Ferdig: {
        icon: 'SuccessFilled',
        fill: 'Green',
        ariaLabel: 'Ferdig'
    },
    'Ikke ledig tolk': {
        icon: 'ErrorFilled',
        fill: 'Red',
        ariaLabel: 'Ikke ledig tolk'
    },
    Avlyst: {
        icon: 'Canceled',
        fill: '',
        ariaLabel: 'Avlyst'
    },
    'Under behandling': {
        icon: 'Scheduled',
        fill: '',
        ariaLabel: 'Under behandling'
    },
    Ukjent: {},
    Åpen: {
        icon: 'Open',
        fill: '',
        ariaLabel: 'Åpen'
    },
    Avslått: {}
};
