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
        List<serviceResourceSkill> serviceResourceSkillList = getServiceResourceSkill();

        for (serviceResourceSkill x : serviceResourceSkillList) {
            for (Skill selectedSkill : selectedSkills) {
                // if (x.Id == selectedSkill.Id) {
                //const removeIndex = serviceResourceSkillList.indexOf(item.Id == selectedSkill.Id);

                //     serviceResourceSkillList.remove(x);
                // }
                System.debug('inside 2 for loops');
                // if (
                //     x.Id == null //&& //selectedSkill.Id != null
                // ) {
                System.debug('make new skills');
                ServiceResourceSkill serviceResourceSkill = new ServiceResourceSkill();
                serviceResourceSkill.ServiceResourceId = serviceResource.Id;
                serviceResourceSkill.SkillId = selectedSkill.Id;
                serviceResourceSkill.EffectiveStartDate = Date.today();

                newServiceResourceSkills.add(serviceResourceSkill);
                //}
                System.debug(newServiceResourceSkills + ' lengde: ' + newServiceResourceSkills.size());
            }
        }
        try {
            upsert newServiceResourceSkills;
            System.debug('upsert completed');
        } catch (Exception e) {
            throw e;
        }

        // refreshapex
    }
}
