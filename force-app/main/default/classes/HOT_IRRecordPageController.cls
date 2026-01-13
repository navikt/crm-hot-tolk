public with sharing class HOT_IRRecordPageController {
    @AuraEnabled(cacheable=true)
    public static List<ServiceAppointment> getRelevantServiceAppointments(String recordId) {
        HOT_InterestedResource__c interestedResource = [
            SELECT ServiceAppointment__c, ServiceAppointment__r.ServiceTerritoryId, ServiceAppointment__r.WorkTypeId
            FROM HOT_InterestedResource__c
            WHERE Id = :recordId
        ];
        List<ServiceAppointment> ServiceAppointments = [
            SELECT
                Id,
                AppointmentNumber,
                EarliestStartTime,
                DueDate,
                HOT_WorkTypeName__c,
                HOT_ServiceTerritoryName__c,
                Status,
                HOT_AssignmentType__c
            FROM ServiceAppointment
            WHERE
                (Status = 'None'
                OR Status = 'Released to Freelance')
                AND Id != :interestedResource.ServiceAppointment__c
                AND ServiceTerritoryId = :interestedResource.ServiceAppointment__r.ServiceTerritoryId
                AND WorkTypeId = :interestedResource.ServiceAppointment__r.WorkTypeId
            ORDER BY EarliestStartTime ASC
        ];
        return ServiceAppointments;
    }
    @AuraEnabled(cacheable=true)
    public static List<HOT_InterestedResource__c> getRelevantInterestedResources(String recordId) {
        ServiceAppointment serviceAppointment = [
            SELECT Id, ParentRecordId
            FROM ServiceAppointment
            WHERE Id = :recordId
            LIMIT 1
        ];

        //Finn og eksludere tjenesteressurser som allerede har interesserte ressurser på dette oppdraget.
        Set<Id> serviceResourcesAlreadyOnThisSA = new Set<Id>();

        for (HOT_InterestedResource__c ir : [
            SELECT ServiceResource__c
            FROM HOT_InterestedResource__c
            WHERE ServiceAppointment__c = :serviceAppointment.Id AND ServiceResource__c != NULL
        ]) {
            serviceResourcesAlreadyOnThisSA.add(ir.ServiceResource__c);
        }

        //Finne relevante tjenesteressurser som har interessert ressurser på andre oppdrag under samme arbeidsordre, men som ikke er tildelt.
        List<HOT_InterestedResource__c> relevantInterestedResources = [
            SELECT
                Id,
                ServiceAppointment__r.Id,
                ServiceAppointment__r.AppointmentNumber,
                ServiceAppointment__c,
                Status__c,
                ServiceAppointment__r.EarliestStartTime,
                ServiceAppointment__r.DueDate,
                ServiceResource__r.Name,
                ResourceAddress__c,
                ServiceTerritory__c,
                CreatedDate
            FROM HOT_InterestedResource__c
            WHERE
                ServiceAppointment__r.ParentRecordId = :serviceAppointment.ParentRecordId
                AND ServiceAppointment__c != :serviceAppointment.Id
                AND Status__c IN ('Interested', 'Not Assigned')
                AND ServiceResource__c NOT IN :serviceResourcesAlreadyOnThisSA
        ];

        return relevantInterestedResources;
    }
}
