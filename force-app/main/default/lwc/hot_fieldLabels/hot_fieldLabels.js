export let requestFieldLabels = {
    Name: { label: 'Bestillingsnummer', type: 'string' },
    ActualUserName__c: { label: 'Brukers navn', type: 'string' },
    AssignmentType__c: { label: 'Anledning', type: 'string' },
    ExternalRequestStatus__c: { label: 'Status', type: 'string' },
    OrdererName__c: { label: 'Bestillers navn', type: 'string' },
    OrdererPhone__c: { label: 'Bestillers mobil', type: 'string' },
    OrdererEmail__c: { label: 'Bestillers e-post', type: 'string' },
    OrganizationNumber__c: { label: 'Organisasjonsnummer', type: 'string' },
    InvoiceReference__c: { label: 'Deres fakturareferanse', type: 'string' },
    AdditionalInvoiceText__c: { label: 'Tilleggsinformajon', type: 'string' },
    Subject__c: { label: 'Tema', type: 'string' },
    Description__c: { label: 'Tilleggsinformasjon', type: 'string' },
    MeetingStreet__c: { label: 'Oppmøteadresse', type: 'string' },
    MeetingPostalCode__c: { label: 'Postnummer', type: 'string' },
    MeetingPostalCity__c: { label: 'Poststed', type: 'string' },
    InterpretationStreet__c: { label: 'Tolkeadresse', type: 'string' },
    InterpretationPostalCode__c: { label: 'Postnummer', type: 'string' },
    InterpretationPostalCity__c: { label: 'Poststed', type: 'string' },
    IsScreenInterpreter__c: {
        label: 'Skjermtolk',
        type: 'Deler av bestillingen gjennomføres som Skjermtolking - Se tidsplan'
    },
    UserInterpretationMethod__c: { label: 'Tolkemetode', type: 'string' },
    UserPreferredInterpreter__c: { label: 'Ønsket tolk', type: 'string' },
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
                Subject__c: this.Subject__c,
                Description__c: this.Description__c,
                MeetingStreet__c: this.MeetingStreet__c,
                MeetingPostalCode__c: this.MeetingPostalCode__c,
                MeetingPostalCity__c: this.MeetingPostalCity__c,
                InterpretationStreet__c: this.InterpretationStreet__c,
                InterpretationPostalCode__c: this.InterpretationPostalCode__c,
                InterpretationPostalCity__c: this.InterpretationPostalCity__c,
                IsScreenInterpreter__c: this.IsScreenInterpreter__c,
                UserPreferredInterpreter__c: this.UserPreferredInterpreter__c,
                AssignmentType__c: this.AssignmentType__c,
                UserInterpretationMethod__c: this.UserInterpretationMethod__c
            };
        }
        return null;
    }
};

export let openServiceAppointmentFieldLabels = {
    AppointmentNumber: { label: 'Oppdragsnummer', type: 'string' },
    HOT_ReleaseDate__c: { label: 'Frigitt dato', type: 'date' },
    HOT_ReleasedBy__c: { label: 'Frigitt av', type: 'string' },
    HOT_NumberOfInterestedResources__c: { label: 'Antall påmeldte', type: 'string' },
    HOT_WorkTypeName__c: { label: 'Tolkemetode', type: 'string' },
    HOT_AssignmentType__c: { label: 'Oppdragstype', type: 'string' },
    HOT_ServiceTerritoryName__c: { label: 'Region', type: 'string' },
    EarliestStartTime: { label: 'Bestilt starttid', type: 'datetime' },
    DueDate: { label: 'Bestilt sluttid', type: 'datetime' },
    HOT_AddressFormated__c: { label: 'Adresse', type: 'string' },
    HOT_FreelanceSubject__c: { label: 'Tema', type: 'string' },
    getSubFields: function (section) {
        if (section === 'details') {
            return {
                AppointmentNumber: this.AppointmentNumber,
                HOT_ReleaseDate__c: this.HOT_ReleaseDate__c,
                HOT_ReleasedBy__c: this.HOT_ReleasedBy__c,
                HOT_NumberOfInterestedResources__c: this.HOT_NumberOfInterestedResources__c,
                HOT_WorkTypeName__c: this.HOT_WorkTypeName__c,
                HOT_AssignmentType__c: this.HOT_AssignmentType__c,
                HOT_ServiceTerritoryName__c: this.HOT_ServiceTerritoryName__c,
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
    AppointmentNumber__c: { label: 'Oppdrag', type: 'string' },
    ServiceAppointmentStartTime__c: { label: 'Bestilt starttid', type: 'datetime' },
    ServiceAppointmentEndTime__c: { label: 'Bestilt sluttid', type: 'datetime' },
    ServiceAppointmentAddress__c: { label: 'Adresse', type: 'string' },
    WorkTypeName__c: { label: 'Tolkemetode', type: 'string' },
    AssignmentType__c: { label: 'Oppdragstype', type: 'string' },
    Status__c: { label: 'Status', type: 'string' },
    NumberOfInterestedResources__c: { label: 'Påmeldte', type: 'string' },
    AppointmentDeadlineDate__c: { label: 'Fristdato', type: 'date' },
    AppointmentServiceTerritory__c: { label: 'Region', type: 'string' },
    ServiceAppointmentFreelanceSubject__c: { label: 'Tema', type: 'string' },
    WorkOrderCanceledDate__c: { label: 'Avlystdato', type: 'datetime' },
    HOT_TermsOfAgreement__c: { label: 'Avtalte betingelser', type: 'string' }
};

export let myServiceAppointmentFieldLabels = {
    AppointmentNumber: { label: 'Oppdragsnummer', type: 'string' },
    HOT_FreelanceSubject__c: { label: 'Tema', type: 'string' },
    EarliestStartTime: { label: 'Bestilt starttid', type: 'datetime' },
    DueDate: { label: 'Bestilt sluttid', type: 'datetime' },
    ActualStartTime: { label: 'Faktisk start', type: 'datetime' },
    ActualEndTime: { label: 'Faktisk slutt', type: 'datetime' },
    HOT_AddressFormated__c: { label: 'Adresse', type: 'string' },
    HOT_ServiceTerritoryName__c: { label: 'Region', type: 'string' },
    Status: { label: 'Status', type: 'string' },
    HOT_HapticCommunication__c: { label: 'Haptisk kommunikasjon', type: 'string' },
    HOT_Escort__c: { label: 'Ledsaging', type: 'string' },
    HOT_DegreeOfHearingAndVisualImpairment__c: { label: 'Vedtak', type: 'string' },
    HOT_WorkTypeName__c: { label: 'Tolkemetode', type: 'string' },
    HOT_TermsOfAgreement__c: { label: 'Avtalte betingelser', type: 'string' },
    Description: { label: 'Tilleggsopplysninger', type: 'string' },
    HOT_Dispatcher__c: { label: 'Formidler', type: 'string' }
};

export let workOrderFieldLabels = {
    StartDate: { label: 'Starttid', type: 'datetime' },
    EndDate: { label: 'Sluttid', type: 'datetime' },
    Subject: { label: 'Tema', type: 'string' },
    HOT_RequestName__c: { label: 'Bestillingsnummer', type: 'string' },
    HOT_ExternalWorkOrderStatus__c: { label: 'Status', type: 'string' },
    HOT_Interpreters__c: { label: 'Tolker', type: 'string' }
};
