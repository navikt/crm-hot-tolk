public without sharing class HOT_FreelanceQualificationsController {
    @AuraEnabled(cacheable=true)
    public static ServiceResource myServiceResource() {
        Id userId = UserInfo.getUserId();
        ServiceResource myFreelanceResource = [SELECT Id FROM ServiceResource WHERE RelatedRecordId = :userId];
        return myFreelanceResource;
    }

    @AuraEnabled(cacheable=true)
    public static List<ServiceResourceSkill> getServiceResourceSkill() {
        Id userId = UserInfo.getUserId();
        ServiceResource freelanceResource = [SELECT Id FROM ServiceResource WHERE RelatedRecordId = :userId];
        List<ServiceResourceSkill> freelanceServiceResourceSkill = [
            SELECT EffectiveStartDate, SkillId, EffectiveEndDate, ServiceResourceId, Id
            FROM ServiceResourceSkill
            WHERE ServiceResourceId = :freelanceResource.Id
            WITH SECURITY_ENFORCED
        ];
        return freelanceServiceResourceSkill;
    }
    @AuraEnabled
    public static void createServiceResourceSkill(ServiceResource serviceResource, List<Skill> selectedSkills) {
        List<ServiceResourceSkill> newServiceResourceSkills = new List<ServiceResourceSkill>();

        for (Skill selectedSkill : selectedSkills) {
            ServiceResourceSkill serviceResourceSkill = new ServiceResourceSkill();
            serviceResourceSkill.ServiceResourceId = serviceResource.Id;
            serviceResourceSkill.SkillId = selectedSkill.Id;
            serviceResourceSkill.EffectiveStartDate = Date.today();

            newServiceResourceSkills.add(serviceResourceSkill);
        }
        try {
            upsert newServiceResourceSkills;
        } catch (DmlException e) {
            throw e;
        }

        // refreshapex
    }
}
