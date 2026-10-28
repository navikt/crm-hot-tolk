public with sharing class HOT_TjenesteleverandorListController {
    @AuraEnabled(cacheable=true)
    public static Integer getTransferredServiceAppointmentsCount() {
        return [
            SELECT COUNT()
            FROM ServiceAppointment
            WHERE
                HOT_IsReleasedToTjenesteleverandor__c = TRUE
                AND HOT_TjenesteleverandorStatus__c = 'Transferred'
                AND Status = 'None'
            WITH USER_MODE
        ];
    }

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
                HOT_UserPreferredGender__c,
                HOT_Request__c,
                HOT_IsOtherEconomicProvicer__c,
                HOT_UserPreferredInterpreter__c,
                HOT_UserInterpretationMethod__c
            FROM ServiceAppointment
            WHERE
                HOT_IsReleasedToTjenesteleverandor__c = TRUE
                AND HOT_TjenesteleverandorStatus__c = 'Transferred'
                AND Status = 'None'
            ORDER BY EarliestStartTime ASC
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<ServiceAppointment> getAcceptedServiceAppointments() {
        return [
            SELECT
                Id,
                Subject,
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
                HOT_NumberOfInterestedResources__c,
                HOT_UserPreferredGender__c,
                HOT_UserPreferredInterpreter__c,
                HOT_UserInterpretationMethod__c,
                HOT_TLDispatcher__r.Name
            FROM ServiceAppointment
            WHERE
                HOT_IsReleasedToTjenesteleverandor__c = TRUE
                AND HOT_TjenesteleverandorStatus__c = 'Accepted'
                AND Status = 'None'
            ORDER BY EarliestStartTime ASC
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<ServiceAppointment> getReleasedServiceAppointments() {
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
                HOT_NumberOfInterestedResources__c,
                HOT_UserPreferredGender__c,
                HOT_UserPreferredInterpreter__c,
                HOT_UserInterpretationMethod__c,
                HOT_TLDispatcher__r.Name
            FROM ServiceAppointment
            WHERE
                HOT_IsReleasedToTjenesteleverandor__c = TRUE
                AND HOT_IsReleasedToFreelance__c = TRUE
                AND HOT_TjenesteleverandorStatus__c = 'Accepted'
                AND Status = 'Released to Freelance'
            ORDER BY EarliestStartTime ASC
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<ServiceAppointment> getDispatchedServiceAppointments() {
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
                HOT_NumberOfInterestedResources__c,
                HOT_UserPreferredGender__c,
                HOT_UserPreferredInterpreter__c,
                HOT_UserInterpretationMethod__c,
                HOT_TLDispatcher__r.Name
            FROM ServiceAppointment
            WHERE
                HOT_IsReleasedToTjenesteleverandor__c = TRUE
                AND HOT_IsReleasedToFreelance__c = TRUE
                AND HOT_TjenesteleverandorStatus__c = 'Accepted'
                AND Status = 'Dispatched'
            ORDER BY EarliestStartTime ASC
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<ServiceAppointment> getFinishedServiceAppointments() {
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
                HOT_NumberOfInterestedResources__c,
                HOT_UserPreferredGender__c,
                HOT_UserPreferredInterpreter__c,
                HOT_UserInterpretationMethod__c,
                HOT_TLDispatcher__r.Name
            FROM ServiceAppointment
            WHERE
                HOT_IsReleasedToTjenesteleverandor__c = TRUE
                AND HOT_TjenesteleverandorStatus__c = 'Accepted'
                AND HOT_IsReleasedToFreelance__c = TRUE
                AND Status IN ('Completed', 'Cannot Complete', 'Canceled', 'Annul')
            ORDER BY EarliestStartTime ASC
        ];
    }
}
