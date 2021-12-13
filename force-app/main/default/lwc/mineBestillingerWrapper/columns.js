export let workOrderColumns = [
    {
        name: 'StartDate',
        label: 'Start tid',
        type: 'String'
    },
    {
        name: 'EndDate',
        label: 'Slutt tid',
        type: 'String'
    },
    {
        name: 'Status',
        label: 'Status',
        type: 'String',
        svg: true
    }
];

export let columns = [
    {
        name: 'StartDate',
        label: 'Start tid',
        type: 'String'
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
