export let workOrderColumns = [
    {
        name: 'StartDate',
        label: 'Start tid',
        type: 'Datetime'
    },
    {
        name: 'EndDate',
        label: 'Slutt tid',
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

export let columns = [
    {
        name: 'StartDate',
        label: 'Start tid',
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
        name: 'StartDate',
        label: 'Start tid',
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
    'Cannot Complete': {
        icon: 'ErrorFilled',
        fill: 'Red',
        ariaLabel: 'Ikke ledig tolk'
    },
    Canceled: {
        icon: 'Warning',
        fill: '',
        ariaLabel: 'Avlyst'
    },
    New: {
        icon: ''
    },
    Reserved: {
        icon: ''
    }
};
