public without sharing class HOT_OpenServiceAppointmentListController {
    @AuraEnabled(cacheable=true)
    public static List<ServiceAppointment> getOpenServiceAppointments() {
        //Getting the skills of the user --> ServiceResource
        Id userId = UserInfo.getUserId();
        List<ServiceResource> serviceResource = [SELECT Id, Name FROM ServiceResource WHERE RelatedRecordId = :userId];

        List<ServiceResourceSkill> serviceResourceSkills = [
            SELECT SkillId
            FROM ServiceResourceSkill
            WHERE ServiceResourceId IN :serviceResource AND (EffectiveEndDate = NULL OR EffectiveEndDate > TODAY)
        ];

        List<Id> mySkillIds = new List<Id>();
        for (ServiceResourceSkill SRSkill : serviceResourceSkills) {
            mySkillIds.add(SRSkill.SkillId);
        }

        List<Skill> mySkills = [SELECT Id, MasterLabel FROM Skill WHERE Id IN :mySkillIds];

        //Getting ServiceAppointments of interest
        List<HOT_InterestedResource__c> interestedResources = [
            SELECT ServiceAppointment__c, ServiceAppointment__r.HOT_WorkOrderLineItem__r.WorkOrder.Id
            FROM HOT_InterestedResource__c
            WHERE ServiceResource__c IN :serviceResource
        ];

        List<Id> interestedServiceAppointmentIds = new List<Id>();
        List<Id> interestedWOIds = new List<Id>();
        for (HOT_InterestedResource__c ir : interestedResources) {
            interestedServiceAppointmentIds.add(ir.ServiceAppointment__c);
            interestedWOIds.add(ir.ServiceAppointment__r.HOT_WorkOrderLineItem__r.WorkOrder.Id);
        }

        //Getting ServiceAppointments, filtered by isRealeased, Status, DeadlineDate
        //and if the ServiceResource has already reported interest in the ServiceAppointment
        List<ServiceAppointment> serviceAppointments = [
            SELECT
                Id,
                HOT_ServiceAppointmentNumber__c,
                HOT_WorkOrderLineItem__r.WorkOrder.Id,
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
                AND HOT_WorkOrderLineItem__r.WorkOrder.Id NOT IN :interestedWOIds
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

        //Removing the ServiceAppointments with needed skills the ServiceResource does not have
        List<ServiceAppointment> serviceAppointmentsFiltered = new List<ServiceAppointment>();
        for (ServiceAppointment sa : serviceAppointments) {
            Integer n = 0;
            for (SkillRequirement sreq : neededSkillRequirements) {
                if (sreq.RelatedRecordId == sa.WorkType.Id) {
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
        List<Thread__c> threadListToInsert = new List<Thread__c>();
        List<Message__c> messageListToInsert = new List<Message__c>();
        Map<Thread__c, String> stringToThreadMap = new Map<Thread__c, String>();
        Id userContactId = HOT_MessageHelper.getUserContactId();
        for (Integer i = 0; i < serviceAppointmentIds.size(); i++) {
            if (!String.isEmpty(comments[i])) {
                Thread__c thread = HOT_InterestedResourcesListController.startAThreadAndAddComment(
                    interestedResources[i].Id,
                    comments[i],
                    userContactId
                );
                threadListToInsert.add(thread);
                stringToThreadMap.put(thread, comments[i]);
            }
        }
        insert threadListToInsert;
        for (Thread__c thread : stringToThreadMap.keySet()) {
            String comment = stringToThreadMap.get(thread);
            Message__c message = HOT_MessageHelper.createMessages(thread.Id, comment, userContactId);
            messageListToInsert.add(message);
        }
        insert messageListToInsert;
    }
}
