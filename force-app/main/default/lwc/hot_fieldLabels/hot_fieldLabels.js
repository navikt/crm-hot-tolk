export let requestFieldLabels = {
    Name: 'Bestillingsnummer',
    ActualUserName__c: 'Brukers navn',
    ExternalRequestStatus__c: 'Status',
    OrdererName__c: 'Bestillers navn',
    OrdererPhone__c: 'Bestillers mobil',
    OrdererEmail__c: 'Bestillers e-post',
    OrganizationNumber__c: 'Organisasjonsnummer',
    InvoiceReference__c: 'Deres fakturareferanse',
    AdditionalInvoiceText__c: 'Tilleggsinformajon',
    EventType__c: 'Type arrangement',
    Subject__c: 'Tema',
    Description__c: 'Tilleggsinformasjon',
    MeetingStreet__c: 'Oppmøteadresse',
    MeetingPostalCode__c: 'Postnummer',
    MeetingPostalCity__c: 'Poststed',
    InterpretationStreet__c: 'Tolkeadresse',
    InterpretationPostalCode__c: 'Postnummer',
    InterpretationPostalCity__c: 'Poststed',
    getSubFields: function (section) {
        if (section === 'user') {
            return {
                ActualUserName__c: this.ActualUserName__c
            };
        }
        if (section === 'orderer') {
            return {
                OrdererName__c: this.OrdererName__c,
                OrdererPhone__c: this.OrdererPhone__c,
                OrdererEmail__c: this.OrdererEmail__c
            };
        }
        if (section === 'company') {
            return {
                OrganizationNumber__c: this.OrganizationNumber__c,
                InvoiceReference__c: this.InvoiceReference__c,
                AdditionalInvoiceText__c: this.AdditionalInvoiceText__c
            };
        }
        if (section === 'request') {
            return {
                Name: this.Name,
                ExternalRequestStatus__c: this.ExternalRequestStatus__c,
                EventType__c: this.EventType__c,
                Subject__c: this.Subject__c,
                Description__c: this.Description__c,
                MeetingStreet__c: this.MeetingStreet__c,
                MeetingPostalCode__c: this.MeetingPostalCode__c,
                MeetingPostalCity__c: this.MeetingPostalCity__c,
                InterpretationStreet__c: this.InterpretationStreet__c,
                InterpretationPostalCode__c: this.InterpretationPostalCode__c,
                InterpretationPostalCity__c: this.InterpretationPostalCity__c
            };
        }
        return null;
    }
};
