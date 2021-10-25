public without sharing class HOT_FreelanceQualificationsController {
    @AuraEnabled(cacheable=true)
    public static ServiceResource myServiceResource() {
        Id userId = UserInfo.getUserId();
        ServiceResource myFreelanceResource = [
            SELECT Id, RelatedRecordId
            FROM ServiceResource
            WHERE RelatedRecordId = :userId
        ];
        return myFreelanceResource;
    }

    @AuraEnabled(cacheable=true)
    public static List<ServiceResourceSkill> getServiceResourceSkill() {
        return getServiceResourceSkillMap().values();
    }

    public static Map<Id, ServiceResourceSkill> getServiceResourceSkillMap() {
        Id userId = UserInfo.getUserId();
        ServiceResource freelanceResource = [SELECT Id FROM ServiceResource WHERE RelatedRecordId = :userId];

        List<ServiceResourceSkill> freelanceServiceResourceSkill = [
            SELECT EffectiveStartDate, SkillId, EffectiveEndDate, ServiceResourceId, Id
            FROM ServiceResourceSkill
            WHERE ServiceResourceId = :freelanceResource.Id
            WITH SECURITY_ENFORCED
        ];
        Map<Id, ServiceResourceSkill> skillMap = new Map<Id, ServiceResourceSkill>();
        for (ServiceResourceSkill srs : freelanceServiceResourceSkill) {
            skillMap.put(srs.SkillId, srs);
        }
        return skillMap;
    }

    public static ServiceResourceSkill setResourceSkill(ServiceResource serviceResource, Skill selectedSkill) {
        ServiceResourceSkill serviceResourceSkill = new ServiceResourceSkill();
        serviceResourceSkill.ServiceResourceId = serviceResource.Id;
        serviceResourceSkill.SkillId = selectedSkill.Id;
        serviceResourceSkill.EffectiveStartDate = Date.today();
        return serviceResourceSkill;
    }

    @AuraEnabled
    public static void createServiceResourceSkill(ServiceResource serviceResource, List<Skill> selectedSkills) {
        List<ServiceResourceSkill> serviceResourceSkillsToDelete = new List<ServiceResourceSkill>();
        List<ServiceResourceSkill> serviceResourceSkillsToCreate = new List<ServiceResourceSkill>();

        Map<Id, ServiceResourceSkill> serviceResourceSkills = getServiceResourceSkillMap();

        Set<Id> selectedSkillsIds = new Set<Id>();
        for (Skill skill : selectedSkills) {
            selectedSkillsIds.add(skill.Id);
            if (!serviceResourceSkills.keySet().contains(skill.Id)) {
                serviceResourceSkillsToCreate.add(setResourceSkill(serviceResource, skill));
            }
        }

        for (Id skillId : serviceResourceSkills.keySet()) {
            if (!selectedSkillsIds.contains(skillId)) {
                serviceResourceSkillsToDelete.add(serviceResourceSkills.get(skillId));
            }
        }

        try {
            insert serviceResourceSkillsToCreate;
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publishSynch();
        }
        try {
            delete serviceResourceSkillsToDelete;
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publishSynch();
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Skill> getAllSkillsList() {
        return HOT_Utility.getSkills();
    }
}
