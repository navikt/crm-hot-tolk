export function formatRecord(record, fieldLabels) {
    let fields = [];
    for (let field in record) {
        if (fieldLabels[field]) {
            fields.push({ name: field, label: fieldLabels[field], value: record[field] });
        }
    }
    return fields;
}

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

export let openServiceAppointmentFieldLabels = {
    AppointmentNumber: 'Oppdragsnummer',
    HOT_ReleaseDate__c: 'Frigitt dato',
    HOT_ReleasedBy__c: 'Frigitt av',
    HOT_NumberOfInterestedResources__c: 'Antall påmeldte',
    HOT_WorkTypeName__c: 'Tolkemetode',
    HOT_AssignmentType__c: 'Oppdragstype',
    ServiceTerritoryName: 'Region',
    EarliestStartTime: 'Start tid',
    DueDate: 'Slutt tid',
    HOT_AddressFormated__c: 'Adresse',
    HOT_FreelanceSubject__c: 'Tema',
    getSubFields: function (section) {
        if (section === 'details') {
            return {
                AppointmentNumber: this.AppointmentNumber,
                HOT_ReleaseDate__c: this.HOT_ReleaseDate__c,
                HOT_ReleasedBy__c: this.HOT_ReleasedBy__c,
                HOT_NumberOfInterestedResources__c: this.HOT_NumberOfInterestedResources__c,
                HOT_WorkTypeName__c: this.HOT_WorkTypeName__c,
                HOT_AssignmentType__c: this.HOT_AssignmentType__c,
                ServiceTerritoryName: this.ServiceTerritoryName,
                EarliestStartTime: this.EarliestStartTime,
                DueDate: this.DueDate,
                HOT_AddressFormated__c: this.HOT_AddressFormated__c,
                HOT_FreelanceSubject__c: this.HOT_FreelanceSubject__c
            };
        }
        if (section === 'comment') {
            return {
                EarliestStartTime: this.EarliestStartTime,
                DueDate: this.DueDate,
                HOT_AddressFormated__c: this.HOT_AddressFormated__c,
                HOT_WorkTypeName__c: this.HOT_WorkTypeName__c,
                HOT_NumberOfInterestedResources__c: this.HOT_NumberOfInterestedResources__c,
                HOT_ReleasedBy__c: this.HOT_ReleasedBy__c,
                HOT_DeadlineDate__c: this.HOT_DeadlineDate__c,
                HOT_FreelanceSubject__c: this.HOT_FreelanceSubject__c
            };
        }
        return null;
    }
};

export let interestedResourceFieldLabels = {
    AppointmentNumber__c: 'Oppdrag',
    ServiceAppointmentStartTime__c: 'Start tid',
    ServiceAppointmentEndTime__c: 'Slutt tid',
    ServiceAppointmentAddress__c: 'Adresse',
    WorkTypeName__c: 'Tolkemetode',
    ServiceAppointment__rHOT_AssignmentType__c: 'Oppdragstype',
    Status__c: 'Status',
    NumberOfInterestedResources__c: 'Påmeldte',
    HOT_DeadlineDate__c: 'Fristdato',
    ServiceAppointment__rServiceTerritoryName: 'Region',
    ServiceAppointment__rHOT_FreelanceSubject__c: 'Tema'
};

export let myServiceAppointmentFieldLabels = {
    AppointmentNumber: 'Oppdragsnummer',
    HOT_FreelanceSubject__c: 'Tema',
    SchedStartTime: 'Planlagt start',
    SchedEndTime: 'Planlagt slutt',
    ActualStartTime: 'Faktisk start',
    ActualEndTime: 'Faktsik slutt',
    Address: 'Adresse',
    ServiceTerritoryName: 'Region',
    Status: 'Status',
    HOT_HapticCommunication__c: 'Haptisk kommunikasjon',
    HOT_Escort__c: 'Ledsaging',
    HOT_DegreeOfHearingAndVisualImpairment__c: 'Vedtak',
    HOT_WorkTypeName__c: 'Tolkemetode',
    HOT_TermsOfAgreement__c: 'Avtalte betingelser'
};

export let workOrderFieldLabels = {
    StartDate: 'Start tid',
    EndDate: 'Slutt tid',
    HOT_RequestName__c: 'Bestillingsnummer',
    HOT_ExternalWorkOrderStatus__c: 'Status',
    HOT_Interpreters__c: 'Tolker'
};
