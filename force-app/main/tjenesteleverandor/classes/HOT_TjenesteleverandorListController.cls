public with sharing class HOT_TjenesteleverandorListController {
    @AuraEnabled(cacheable=true)
    public static List<ServiceAppointment> getTransferredServiceAppointments() {
        return [
            SELECT
                Id,
                EarliestStartTime,
                toLabel(Status),
                DueDate,
                HOT_FreelanceSubject__c,
                HOT_AddressFormated__c,
                HOT_WorkTypeName__c,
                AppointmentNumber,
                HOT_TjenesteleverandorStatus__c,
                HOT_TjenesteleverandorTransferDate__c,
                HOT_TjenesteleverandorDeadline__c,
                HOT_Information__c,
                HOT_PreparationTime__c,
                HOT_ServiceTerritoryDeveloperName__c,
                HOT_ServiceTerritoryName__c,
                HOT_DeadlineDate__c,
                HOT_IsSerieoppdrag__c,
                HOT_NumberOfInterestedResources__c,
                HOT_ReleasedBy__c,
                HOT_ReleaseDate__c,
                HOT_AssignmentType__c,
                HOT_Request__c,
                HOT_IsOtherEconomicProvicer__c
            FROM ServiceAppointment
            WHERE
                HOT_TjenesteleverandorStatus__c = 'Transferred'
                AND Status = 'Released to Freelance'
                AND HOT_IsReleasedToFreelance__c = TRUE
            WITH USER_MODE
            ORDER BY EarliestStartTime ASC
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<ServiceAppointment> getAcceptedServiceAppointments() {
        return [
            SELECT
                Id,
                EarliestStartTime,
                toLabel(Status),
                DueDate,
                HOT_FreelanceSubject__c,
                HOT_AddressFormated__c,
                HOT_WorkTypeName__c,
                AppointmentNumber,
                HOT_Information__c,
                HOT_PreparationTime__c,
                HOT_ServiceTerritoryDeveloperName__c,
                HOT_ServiceTerritoryName__c,
                HOT_TjenesteleverandorStatus__c,
                HOT_TjenesteleverandorTransferDate__c,
                HOT_TjenesteleverandorAcceptDate__c,
                HOT_AssignmentType__c,
                HOT_Request__c,
                HOT_IsOtherEconomicProvicer__c,
                HOT_ReleasedBy__c,
                HOT_ReleaseDate__c,
                HOT_DeadlineDate__c,
                HOT_NumberOfInterestedResources__c
            FROM ServiceAppointment
            WHERE HOT_TjenesteleverandorStatus__c = 'Accepted'
            WITH USER_MODE
            ORDER BY EarliestStartTime ASC
        ];
    }
}
