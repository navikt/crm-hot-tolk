public without sharing class HOT_WageClaimListController {
    @AuraEnabled(cacheable=true)
    public static List<HOT_WageClaim__c> getAvailableResources(Id recordId) {
        ServiceAppointment serviceAppointment = [
            SELECT Id, SchedStartTime, SchedEndTime, ServiceTerritoryId, WorkTypeId
            FROM ServiceAppointment
            WHERE Id = :recordId
        ];
        List<Id> requiredSkills = getWorkTypeSkills(new List<Id>{ serviceAppointment.WorkTypeId })
            .get(serviceAppointment.WorkTypeId);

        List<HOT_WageClaim__c> wageClaims = [
            SELECT
                Id,
                StartTime__c,
                EndTime__c,
                ServiceResource__r.Name,
                ServiceResource__c,
                ServiceResource__r.HOT_ServiceTerritory__r.Name
            FROM HOT_WageClaim__c
            WHERE
                Type__c = 'Available on Wage'
                AND Status__c = 'Open'
                AND ((StartTime__c > :serviceAppointment.SchedStartTime
                AND StartTime__c < :serviceAppointment.SchedEndTime)
                OR (EndTime__c > :serviceAppointment.SchedStartTime
                AND EndTime__c < :serviceAppointment.SchedEndTime)
                OR (StartTime__c <= :serviceAppointment.SchedStartTime
                AND EndTime__c >= :serviceAppointment.SchedEndTime))
        ];
        List<Id> serviceResourceIds = new List<Id>();
        for (HOT_WageClaim__c wageClaim : wageClaims) {
            serviceResourceIds.add(wageClaim.ServiceResource__c);
        }
        Map<Id, List<Id>> skillsByResource = getServiceResourceSkills(serviceResourceIds);

        List<HOT_WageClaim__c> relevantWageClaims = new List<HOT_WageClaim__c>();
        for (HOT_WageClaim__c wageClaim : wageClaims) {
            if (hasRequiredSkills(requiredSkills, skillsByResource.get(wageClaim.ServiceResource__c))) {
                relevantWageClaims.add(wageClaim);
            }
        }

        return relevantWageClaims;
    }

    @AuraEnabled(cacheable=true)
    public static List<HOT_WageClaim__c> getMyWageClaims() {
        List<HOT_WageClaim__c> wageClaims = [
            SELECT Id, StartTime__c, EndTime__c, AssignmentType__c, WorkTypeName__c, Status__c, ServiceTerritoryName__c
            FROM HOT_WageClaim__c
            WHERE
                Type__c = 'Available on Wage'
                AND Status__c = 'Open'
                AND ServiceResource__r.RelatedRecordId = :UserInfo.getUserId()
        ];
        return wageClaims;
    }

    @AuraEnabled
    public static void retractAvailability(Id recordId) {
        HOT_WageClaim__c wageClaim = new HOT_WageClaim__c(Id = recordId);
        wageClaim.Status__c = 'Retracted Availability';
        try {
            update wageClaim;
        } catch (Exception e) {
            throw e;
        }
    }

    public static Map<Id, List<Id>> getServiceResourceSkills(List<Id> serviceResourceIds) {
        List<ServiceResourceSkill> serviceResourceSkills = [
            SELECT Id, SkillId, ServiceResourceId
            FROM ServiceResourceSkill
            WHERE ServiceResourceId IN :serviceResourceIds
        ];
        Map<Id, List<Id>> skillsByServiceResource = new Map<Id, List<Id>>();
        for (ServiceResourceSkill serviceResourceSkill : serviceResourceSkills) {
            if (skillsByServiceResource.get(serviceResourceSkill.ServiceResourceId) == null) {
                skillsByServiceResource.put(
                    serviceResourceSkill.ServiceResourceId,
                    new List<Id>{ serviceResourceSkill.SkillId }
                );
            } else {
                skillsByServiceResource.get(serviceResourceSkill.ServiceResourceId).add(serviceResourceSkill.SkillId);
            }
        }
        return skillsByServiceResource;
    }

    public static Map<Id, List<Id>> getWorkTypeSkills(List<Id> workTypeIds) {
        List<SkillRequirement> skillRequirements = [
            SELECT Id, SkillId, RelatedRecordId
            FROM SkillRequirement
            WHERE RelatedRecordId IN :workTypeIds
        ];
        Map<Id, List<Id>> skillsByWorkType = new Map<Id, List<Id>>();
        for (SkillRequirement skillRequirement : skillRequirements) {
            if (skillsByWorkType.get(skillRequirement.RelatedRecordId) == null) {
                skillsByWorkType.put(skillRequirement.RelatedRecordId, new List<Id>{ skillRequirement.SkillId });
            } else {
                skillsByWorkType.get(skillRequirement.RelatedRecordId).add(skillRequirement.SkillId);
            }
        }
        return skillsByWorkType;
    }

    public static Boolean hasRequiredSkills(List<Id> requiredSkills, List<Id> skills) {
        Integer numberOfSkills = 0;
        for (Id skillId : requiredSkills) {
            numberOfSkills += skills.contains(skillId) ? 1 : 0;
        }
        return numberOfSkills == requiredSkills.size();
    }
}
