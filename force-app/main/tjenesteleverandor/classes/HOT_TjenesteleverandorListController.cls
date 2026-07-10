public without sharing class HOT_TjenesteleverandorListController {
    @AuraEnabled(cacheable=true)
    public static List<ServiceAppointment> getTransferredServiceAppointments() {
        return [
            SELECT
                Id,
                EarliestStartTime,
                DueDate,
                HOT_FreelanceSubject__c,
                HOT_AddressFormated__c,
                HOT_WorkTypeName__c,
                HOT_ServiceAppointmentNumber__c,
                HOT_TjenesteleverandorStatus__c,
                HOT_TjenesteleverandorTransferDate__c,
                HOT_Information__c,
                HOT_PreparationTime__c,
                WorkTypeId,
                HOT_ServiceTerritoryName__c
            FROM ServiceAppointment
            WHERE
                HOT_TjenesteleverandorStatus__c = 'Transferred'
                AND Status = 'Released to Freelance'
                AND HOT_IsReleasedToFreelance__c = TRUE
            ORDER BY EarliestStartTime ASC
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<ServiceAppointment> getAcceptedServiceAppointments() {
        return [
            SELECT
                Id,
                EarliestStartTime,
                DueDate,
                HOT_FreelanceSubject__c,
                HOT_AddressFormated__c,
                HOT_WorkTypeName__c,
                HOT_ServiceAppointmentNumber__c,
                HOT_TjenesteleverandorStatus__c,
                HOT_TjenesteleverandorAcceptDate__c,
                HOT_Information__c,
                HOT_PreparationTime__c,
                WorkTypeId,
                HOT_ServiceTerritoryName__c
            FROM ServiceAppointment
            WHERE HOT_TjenesteleverandorStatus__c = 'Accepted'
            ORDER BY EarliestStartTime ASC
        ];
    }
}
