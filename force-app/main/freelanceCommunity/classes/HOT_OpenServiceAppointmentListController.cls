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

        //Getting ServiceAppointments of interest. Null ettersom det IR får denne status når oppdrag frigis på nytt og skal være mulig å melde seg på på nytt
        List<HOT_InterestedResource__c> interestedResources = [
            SELECT ServiceAppointment__c, ServiceAppointment__r.HOT_WorkOrderLineItem__r.WorkOrder.Id
            FROM HOT_InterestedResource__c
            WHERE ServiceResource__c IN :serviceResource AND Status__c != NULL
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
                Street,
                PostalCode,
                HOT_AssignmentType__c,
                HOT_AssignmentCategory__c,
                HOT_Information__c,
                HOT_IsScreenInterpreterNew__c,
                HOT_Request__r.IsFellesOppdrag__c,
                HOT_Request__r.OwnerName__c,
                HOT_Request__r.IsOtherEconomicProvicer__c,
                HOT_PreparationTime__c
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

        ServiceResource serviceResource = [SELECT Id FROM ServiceResource WHERE RelatedRecordId = :userId LIMIT 1];

        /* Mappe ServiceAppointment → Comment */
        Map<Id, String> appointmentToComment = new Map<Id, String>();
        for (Integer i = 0; i < serviceAppointmentIds.size(); i++) {
            appointmentToComment.put(
                (Id) serviceAppointmentIds[i],
                comments != null && comments.size() > i ? comments[i] : null
            );
        }

        Set<Id> serviceAppointmentIdSet = appointmentToComment.keySet();

        /* Finn eksisterende Interessert ressurs (MED alle felter som trengs for Thread) */
        Map<Id, HOT_InterestedResource__c> serviceAppointmentToIR = new Map<Id, HOT_InterestedResource__c>();

        for (HOT_InterestedResource__c ir : [
            SELECT
                Id,
                ServiceAppointment__c,
                Status__c,
                ServiceResource__r.AccountId,
                ServiceAppointment__r.Subject,
                ServiceAppointment__r.HOT_Account__c,
                ServiceAppointment__r.HOT_Request__r.Dispatcher__c
            FROM HOT_InterestedResource__c
            WHERE ServiceResource__c = :serviceResource.Id AND ServiceAppointment__c IN :serviceAppointmentIdSet
        ]) {
            serviceAppointmentToIR.put(ir.ServiceAppointment__c, ir);
        }

        /* Opprett / oppdater Interessert ressurs */
        List<HOT_InterestedResource__c> irsToInsert = new List<HOT_InterestedResource__c>();
        List<HOT_InterestedResource__c> irsToUpdate = new List<HOT_InterestedResource__c>();

        for (Id saId : serviceAppointmentIdSet) {
            if (!serviceAppointmentToIR.containsKey(saId)) {
                HOT_InterestedResource__c ir = new HOT_InterestedResource__c(
                    ServiceAppointment__c = saId,
                    ServiceResource__c = serviceResource.Id,
                    Status__c = 'Interested',
                    Comments__c = appointmentToComment.get(serviceAppointmentId)
                );
                irsToInsert.add(ir);
                serviceAppointmentToIR.put(saId, ir);
            } else {
                HOT_InterestedResource__c existingIR = serviceAppointmentToIR.get(saId);
                if (String.isBlank(existingIR.Status__c)) {
                    existingIR.Status__c = 'Interested';
                    existingIR.Status__c = appointmentToComment.get(serviceAppointmentId);
                    irsToUpdate.add(existingIR);
                }
            }
        }

        if (!irsToUpdate.isEmpty()) {
            update irsToUpdate;
        }
        if (!irsToInsert.isEmpty()) {
            insert irsToInsert;
        }

        Id userContactId = HOT_MessageHelper.getUserContactId();

        /* Hent eksisterende Threads */
        Set<Id> interestedResoureIds = new Set<Id>();
        for (HOT_InterestedResource__c ir : serviceAppointmentToIR.values()) {
            if (ir.Id != null) {
                interestedResoureIds.add(ir.Id);
            }
        }

        Map<Id, Thread__c> irIdToThread = new Map<Id, Thread__c>();

        if (!interestedResoureIds.isEmpty()) {
            for (Thread__c t : [
                SELECT Id, CRM_Related_Object__c, CRM_Thread_Type__c
                FROM Thread__c
                WHERE CRM_Related_Object__c IN :interestedResoureIds
            ]) {
                irIdToThread.put(t.CRM_Related_Object__c, t);
            }
        }

        /* Lage nye tråder + Meldinger */
        List<Thread__c> newThreads = new List<Thread__c>();
        Map<Id, String> irIdToComment = new Map<Id, String>();
        List<Message__c> messagesToInsert = new List<Message__c>();

        for (Id saId : serviceAppointmentToIR.keySet()) {
            String comment = appointmentToComment.get(saId);
            if (String.isBlank(comment)) {
                continue;
            }

            HOT_InterestedResource__c ir = serviceAppointmentToIR.get(saId);

            if (irIdToThread.containsKey(ir.Id)) {
                Thread__c t = irIdToThread.get(ir.Id);
                messagesToInsert.add(HOT_MessageHelper.createMessages(t, comment, userContactId));
            } else {
                Thread__c thread = HOT_InterestedResourcesListController.buildThread(ir, userContactId);
                newThreads.add(thread);
                irIdToComment.put(ir.Id, comment);
            }
        }

        if (!newThreads.isEmpty()) {
            insert newThreads;
        }

        for (Thread__c t : newThreads) {
            String msg = irIdToComment.get(t.CRM_Related_Object__c);
            if (String.isBlank(msg))
                continue;
            messagesToInsert.add(HOT_MessageHelper.createMessages(t, msg, userContactId));
        }

        if (!messagesToInsert.isEmpty()) {
            insert messagesToInsert;
        }
    }
}
