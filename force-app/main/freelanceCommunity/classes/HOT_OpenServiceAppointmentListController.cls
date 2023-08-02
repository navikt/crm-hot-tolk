public without sharing class HOT_OpenServiceAppointmentListController {
    @AuraEnabled(cacheable=true)
    public static List<ServiceAppointment> getOpenServiceAppointments() {
        //Getting the skills of the user --> ServiceResource
        Id userId = UserInfo.getUserId();
        List<ServiceResource> serviceResource = [SELECT Id, Name FROM ServiceResource WHERE RelatedRecordId = :userId];

        List<ServiceResourceSkill> serviceResourceSkills = [
            SELECT SkillId
            FROM ServiceResourceSkill
            WHERE ServiceResourceId IN :serviceResource
        ];

        List<Id> mySkillIds = new List<Id>();
        for (ServiceResourceSkill SRSkill : serviceResourceSkills) {
            mySkillIds.add(SRSkill.SkillId);
        }

        //List<Skill> mySkills = [SELECT Id, MasterLabel FROM Skill WHERE Id IN: mySkillIds];

        //Getting ServiceAppointments of interest
        List<HOT_InterestedResource__c> interestedResources = [
            SELECT ServiceAppointment__c
            FROM HOT_InterestedResource__c
            WHERE ServiceResource__c IN :serviceResource
        ];
        List<Id> interestedServiceAppointmentIds = new List<Id>();
        for (HOT_InterestedResource__c ir : interestedResources) {
            interestedServiceAppointmentIds.add(ir.ServiceAppointment__c);
        }

        //Getting ServiceAppointments, filtered by isRealeased, Status, DeadlineDate
        //and if the ServiceResource has already reported interest in the ServiceAppointment
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
                AND Id NOT IN :interestedServiceAppointmentIds
                AND ServiceTerritoryId != NULL
            ORDER BY EarliestStartTime ASC
        ];

        //Getting the required Skills for each workType
        Set<Id> workTypeIds = new Set<Id>();
        for (ServiceAppointment sa : serviceAppointments) {
            workTypeIds.add(sa.WorkType.Id);
        }

        List<SkillRequirement> neededSkillRequirements = [
            SELECT SkillId, RelatedRecordId
            FROM SkillRequirement
            WHERE RelatedRecordId IN :workTypeIds
        ];

        List<Id> neededSkillIds = new List<Id>();
        for (SkillRequirement req : neededSkillRequirements) {
            neededSkillIds.add(req.SkillId);
        }

        List<Skill> neededSkills = [SELECT Id FROM Skill WHERE Id IN :neededSkillIds];

        //Removing the ServiceAppointments with needed skills the ServiceResource does not have
        List<ServiceAppointment> serviceAppointmentsFiltered = new List<ServiceAppointment>();
        for (ServiceAppointment sa : serviceAppointments) {
            List<Id> subNeededSkillIds = new List<Id>();
            Integer n = 0;
            for (SkillRequirement sreq : neededSkillRequirements) {
                if (sreq.RelatedRecordId == sa.WorkType.Id) {
                    subNeededSkillIds.add(sreq.SkillId);
                    if (!mySkillIds.contains(sreq.SkillId)) {
                        n++;
                    }
                }
            }
            if (n == 0) {
                serviceAppointmentsFiltered.add(sa);
            }
        }
        return serviceAppointmentsFiltered;
    }

    @AuraEnabled
    public static void createInterestedResources(List<String> serviceAppointmentIds, List<String> comments) {
        Id userId = UserInfo.getUserId();
        ServiceResource serviceResource = [SELECT Id FROM ServiceResource WHERE RelatedRecordId = :userId];
        List<HOT_InterestedResource__c> interestedResources = new List<Hot_InterestedResource__c>();
        for (Integer i = 0; i < serviceAppointmentIds.size(); i++) {
            HOT_InterestedResource__c IR = new HOT_InterestedResource__c(
                ServiceAppointment__c = serviceAppointmentIds[i],
                ServiceResource__c = serviceResource.Id,
                Status__c = 'Interested'
            );
            interestedResources.add(IR);
        }
        insert interestedResources;

        for (Integer i = 0; i < serviceAppointmentIds.size(); i++) {
            if(!String.isEmpty(comments[i])) {
                HOT_InterestedResourcesListController.startAThreadAndAddComment(interestedResources[i].Id, comments[i]);
            }
        }
    }
}
