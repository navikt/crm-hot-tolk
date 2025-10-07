export let workOrderColumns = [
    { label: 'Tid', fieldName: 'StartAndEndDate' },
    { label: 'Tolk', fieldName: 'HOT_Interpreters__c' },
    { label: 'Status', fieldName: 'Status' },
    { label: 'Adresse', fieldName: 'HOT_AddressFormated__c' }
];

export let columns = [
    { label: 'Tid', fieldName: 'StartAndEndDate' },
    { label: 'Tema', fieldName: 'Subject' },
    { label: 'Status', fieldName: 'Status' },
    { label: 'Adresse', fieldName: 'HOT_AddressFormated__c' }
];

export let labelMap = {
    Status: {
        Ferdig: { label: 'Ferdig', cssClass: 'label-green' },
        Åpen: { label: 'Åpen', cssClass: 'label-gray' },
        Avlyst: { label: 'Avlyst', cssClass: 'label-red' },
        'Du har fått tolk': { label: 'Du har fått tolk', cssClass: 'label-green' },
        'Under behandling': { label: 'Under behandling', cssClass: 'label-orange' },
        'Ikke ledig tolk': { label: 'Ikke ledig tolk', cssClass: 'label-red' },
        Pågår: { label: 'Pågår', cssClass: 'label-blue' },
        Avslått: { label: 'Avslått', cssClass: 'label-red' }
    }
};
