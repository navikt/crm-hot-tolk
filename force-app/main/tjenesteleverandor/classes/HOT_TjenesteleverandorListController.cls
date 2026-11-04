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
                HOT_UserInterpretationMethod__c,
                HOT_Request__r.Subject__c,
                HOT_Request__r.Person__r.HOT_Reservations__c,
                HOT_Request__r.Person__r.HOT_LanguageAndCommunicationMethods__c
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
                HOT_TLDispatcher__r.Name,
                HOT_Request__r.Person__r.HOT_Reservations__c,
                HOT_Request__r.Person__r.HOT_LanguageAndCommunicationMethods__c
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
                HOT_TLDispatcher__r.Name,
                HOT_Request__r.Person__r.HOT_Reservations__c,
                HOT_Request__r.Person__r.HOT_LanguageAndCommunicationMethods__c
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
                HOT_TLDispatcher__r.Name,
                HOT_Request__r.Person__r.HOT_Reservations__c,
                HOT_Request__r.Person__r.HOT_LanguageAndCommunicationMethods__c
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
                HOT_TLDispatcher__r.Name,
                HOT_Request__r.Person__r.HOT_Reservations__c,
                HOT_Request__r.Person__r.HOT_LanguageAndCommunicationMethods__c
            FROM ServiceAppointment
            WHERE
                HOT_IsReleasedToTjenesteleverandor__c = TRUE
                AND HOT_TjenesteleverandorStatus__c = 'Accepted'
                AND HOT_IsReleasedToFreelance__c = TRUE
                AND Status IN ('Completed', 'Cannot Complete', 'Canceled', 'Annul')
            ORDER BY EarliestStartTime ASC
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<ServiceResource> getServiceResources() {
        return [
            SELECT
                Id,
                Name,
                HOT_InterpreterType__c,
                IsActive,
                HOT_ServiceTerritory__r.Name,
                HOT_ServiceTerritory__r.HOT_DeveloperName__c
            FROM ServiceResource
            WHERE HOT_IsFreelanceInterpreter__c = TRUE
            ORDER BY IsActive DESC
        ];
    }

    @AuraEnabled(cacheable=true)
    public static ServiceResource getSRDetails(Id recordId) {
        return [
            SELECT
                Id,
                HOT_Address__c,
                HOT_Email__c,
                HOT_MobilePhone__c,
                HOT_MobileDevice__c,
                HOT_NotificationChannel__c,
                Name,
                IsActive,
                HOT_PreferredRegions__c,
                HOT_Skilled__c,
                HOT_ServiceTerritory__c,
                HOT_MoreInformation__c,
                Description
            FROM ServiceResource
            WHERE Id = :recordId
            LIMIT 1
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<ServiceResourceSkill> getServiceResourceSkills(Id resourceId) {
        return [
            SELECT EffectiveStartDate, SkillId, EffectiveEndDate, ServiceResourceId, Id, Skill.MasterLabel
            FROM ServiceResourceSkill
            WHERE ServiceResourceId = :resourceId
            WITH SECURITY_ENFORCED
        ];
    }
}
