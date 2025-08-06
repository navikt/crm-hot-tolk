export let workOrderColumns = [
    {
        label: 'Tid',
        fieldName: 'StartAndEndDate'
    },
    {
        label: 'Status',
        fieldName: 'Status'
    },
    {
        label: 'Adresse',
        fieldName: 'HOT_AddressFormated__c'
    },
    {
        label: 'Tolk',
        fieldName: 'HOT_Interpreters__c'
    }
];

export let columns = [
    {
        label: 'Tid',
        fieldName: 'StartAndEndDate'
    },
    {
        label: 'Status',
        fieldName: 'Status'
    },
    {
        label: 'Tema',
        fieldName: 'Subject'
    },
    {
        label: 'Adresse',
        fieldName: 'HOT_AddressFormated__c'
    }
];

export let labelMap = {
    Status: {
        Completed: { label: 'Ferdig', cssClass: 'label-green' },
        New: { label: 'Åpen', cssClass: 'label-gray' },
        Canceled: { label: 'Avlyst', cssClass: 'label-red' },
        Dispatched: { label: 'Du har fått tolk', cssClass: 'label-green' },
        Scheduled: { label: 'Under behandling', cssClass: 'label-orange' },
        'Partially Complete': { label: 'Ferdig', cssClass: 'label-green' },
        'Cannot Complete': { label: 'Ikke ledig tolk', cssClass: 'label-red' }
    }
};
