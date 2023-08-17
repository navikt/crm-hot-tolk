public without sharing class HOT_wantedSRListController {
      @AuraEnabled(cacheable=true)
    public static List<ServiceAppointment> getWantedServiceAppointments() {
        Id userId = UserInfo.getUserId();
        List<ServiceResource> serviceResource = [SELECT Id, Name FROM ServiceResource WHERE RelatedRecordId = :userId];

        //Getting wanted ServiceAppointments
        List<HOT_InterestedResource__c> interestedResources = [
            SELECT Id, ServiceAppointment__c
            FROM HOT_InterestedResource__c
            WHERE ServiceResource__c IN :serviceResource AND Status__c='Wanted'];

        Set<Id> saIds=new Set<Id>();
        for (HOT_InterestedResource__c ir : interestedResources) {
            saIds.add(ir.ServiceAppointment__c);
        }

        List<ServiceAppointment> serviceAppointments = [
            SELECT
                Id,
                HOT_ServiceAppointmentNumber__c,
                ServiceTerritoryId,
                EarliestStartTime,
                DueDate,
                HOT_DeadlineDate__c,
                HOT_FreelanceSubject__c,
                HOT_AddressFormated__c,
                HOT_IsSerieoppdrag__c,
                Address,
                HOT_InterpretationStreet__c,
                HOT_InterpretationPostalCode__c,
                HOT_WorkTypeName__c,
                HOT_NumberOfInterestedResources__c,
                WorkType.Id,
                HOT_RequestNumber__c,
                HOT_ReleasedBy__c,
                ServiceTerritory.Name,
                ServiceTerritory.HOT_DeveloperName__c,
                HOT_ServiceTerritoryDeveloperName__c,
                HOT_ServiceTerritoryName__c,
                HOT_ReleaseDate__c,
                City,
                HOT_IsUrgent__c,
                Street,
                PostalCode,
                HOT_AssignmentType__c,
                HOT_AssignmentCategory__c,
                HOT_Information__c,
                HOT_IsScreenInterpreterNew__c,
                HOT_Request__r.IsFellesOppdrag__c,
                HOT_Request__r.OwnerName__c
            FROM ServiceAppointment
            WHERE
                HOT_IsReleasedToFreelance__c = TRUE
                AND Status = 'Released To Freelance'
                AND HOT_DeadlineDate__c >= :DATE.TODAY()
                AND Id IN :saIds
                AND ServiceTerritoryId != NULL
            ORDER BY EarliestStartTime ASC
        ];
        return serviceAppointments;
    }
    @AuraEnabled
    public static void updateInterestedResource(Id saId, Id srId) {
     HOT_InterestedResource__c interestedResource = [
            SELECT Id, ServiceAppointment__c, ServiceResource__c
            FROM HOT_InterestedResource__c
            WHERE ServiceResource__c =:srId AND Status__c='Wanted' AND ServiceAppointment__c=:saId LIMIT 1];
        
        if(interestedResource!=null){
        interestedResource.Status__c = 'Assigned';
        
        update interestedResource;

        AssignedResource assignedResource = new AssignedResource(
                        ServiceAppointmentId = interestedResource.ServiceAppointment__c,
                        ServiceResourceId = interestedResource.ServiceResource__c
                    );
        insert assignedResource;

        ServiceAppointment sa=[SELECT Id, Status FROM ServiceAppointment WHERE Id = :saId];
        sa.Status='Dispatched';
        update sa;


        }
    }
     @AuraEnabled
    public static void declineInterestedResource(Id saId, Id srId) {

        HOT_InterestedResource__c interestedResource = [
            SELECT Id, ServiceAppointment__c, ServiceResource__c
            FROM HOT_InterestedResource__c
            WHERE ServiceResource__c =:srId AND Status__c='Wanted' AND ServiceAppointment__c=:saId LIMIT 1];
        
        if(interestedResource!=null){
        interestedResource.Status__c = 'Declined';
        
        update interestedResource;

        }
    }
}