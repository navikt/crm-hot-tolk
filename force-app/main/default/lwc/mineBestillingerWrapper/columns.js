export let workOrderColumns = [
    {
        name: 'StartAndEndDate',
        label: 'Tid',
        type: 'Datetime'
    },
    {
        name: 'Status',
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
        name: 'Status',
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
        name: 'Status',
        label: 'Status',
        type: 'String',
        svg: true
    },
    {
        name: 'Subject',
        label: 'Emne',
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
        name: 'Status',
        label: 'Status',
        type: 'String',
        svg: true
    },
    {
        name: 'Subject',
        label: 'Emne',
        type: 'String'
    }
];

export let iconByValue = {
    Dispatched: {
        icon: 'SuccessFilled',
        fill: 'Green',
        ariaLabel: 'Du har fått tolk'
    },
    Completed: {
        icon: 'SuccessFilled',
        fill: 'Green',
        ariaLabel: 'Ferdig'
    },
    'Cannot Complete': {
        icon: 'ErrorFilled',
        fill: 'Red',
        ariaLabel: 'Ikke ledig tolk'
    },
    Canceled: {
        icon: 'Canceled',
        fill: '',
        ariaLabel: 'Avlyst'
    },
    New: {
        icon: ''
    },
    Reserved: {
        icon: ''
    },
    Scheduled: {
        icon: ''
    }
};
