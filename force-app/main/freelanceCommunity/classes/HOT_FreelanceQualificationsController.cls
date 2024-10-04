public without sharing class HOT_FreelanceQualificationsController {
    private static void handleException(Exception e) {
        LoggerUtility logger = new LoggerUtility();
        logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
        logger.publishSynch();
    }
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
    public static List<ServiceResourceSkill> getUserServiceResourceSkills() {
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
    public static void editServiceResourceSkill(List<Skill> selectedSkills) {
        ServiceResource serviceResource = myServiceResource();
        List<ServiceResourceSkill> serviceResourceSkillsToUpdateEndDate = new List<ServiceResourceSkill>();
        List<ServiceResourceSkill> serviceResourceSkillsToCreate = new List<ServiceResourceSkill>();

        Map<Id, ServiceResourceSkill> serviceResourceSkills = getServiceResourceSkillMap();

        Set<Id> selectedSkillsIds = new Set<Id>();
        for (Skill skill : selectedSkills) {
            selectedSkillsIds.add(skill.Id);
            // Create Skill not yet existing on user
            if (!serviceResourceSkills.keySet().contains(skill.Id)) {
                serviceResourceSkillsToCreate.add(setResourceSkill(serviceResource, skill));
            }
            // Set Skill EffectiveEndDate to null if Skill already exists on user
            if (
                serviceResourceSkills.keySet().contains(skill.Id) &&
                serviceResourceSkills.get(skill.Id).EffectiveEndDate != null
            ) {
                serviceResourceSkills.get(skill.Id).EffectiveEndDate = null;
                serviceResourceSkillsToUpdateEndDate.add(serviceResourceSkills.get(skill.Id));
            }
        }
        for (Id skillId : serviceResourceSkills.keySet()) {
            if (!selectedSkillsIds.contains(skillId) && serviceResourceSkills.get(skillId).EffectiveEndDate == null) {
                serviceResourceSkills.get(skillId).EffectiveEndDate = Datetime.now();
                serviceResourceSkillsToUpdateEndDate.add(serviceResourceSkills.get(skillId));
            }
        }

        try {
            insert serviceResourceSkillsToCreate;
        } catch (Exception e) {
            handleException(e);
        }
        try {
            update serviceResourceSkillsToUpdateEndDate;
        } catch (Exception e) {
            handleException(e);
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Skill> getAllSkillsList() {
        return HOT_Utility.getSkills();
    }
}
