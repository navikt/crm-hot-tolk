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
        Map<Id, ServiceResourceSkill> skillMap = getServiceResourceSkillMap();
        Set<Id> selectedSkillsIds = new Set<Id>();

        for (Skill selectedSkill : selectedSkills) {
            selectedSkillsIds.add(selectedSkill.Id);
        }
        if (selectedSkills.isEmpty()) {
            for (serviceResourceSkill x1 : skillMap.values()) {
                x1.EffectiveEndDate = Date.today();
            }
        }
        for (Skill selectedSkill : selectedSkills) {
            if (!skillMap.containsKey(selectedSkill.Id)) {
                skillMap.put(selectedSkill.Id, setResourceSkill(serviceResource, selectedSkill));
            } else {
                skillMap.get(selectedSkill.Id).EffectiveEndDate = null;
            }
        }
        for (Id skillId : skillMap.keySet()) {
            if (!selectedSkillsIds.contains(skillId)) {
                skillMap.get(skillId).EffectiveEndDate = Date.today();
            }
        }

        try {
            upsert skillMap.values();
        } catch (Exception e) {
            throw e;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Skill> getAllSkillsList() {
        List<Skill> allSkills = [SELECT Id, MasterLabel FROM Skill WHERE DeveloperName != 'Bildetolkvakt'];
        return allSkills;
    }
}
