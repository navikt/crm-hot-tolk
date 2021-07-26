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
        List<ServiceResourceSkill> currentSkillList = getServiceResourceSkill();

        for (Skill selectedSkill : selectedSkills) {
            ServiceResourceSkill serviceResourceSkill = new ServiceResourceSkill();
            serviceResourceSkill.ServiceResourceId = serviceResource.Id;
            serviceResourceSkill.SkillId = selectedSkill.Id;
            serviceResourceSkill.EffectiveStartDate = Date.today();
            // if (
            //     serviceResourceSkill.EffectiveStartDate == null ||
            //     serviceResourceSkill.EffectiveStartDate == undefined
            // ) {
            // }
            for (serviceResourceSkill currentSkill : currentSkillList) {
                if (currentSkill.SkillId == selectedSkill.Id) {
                    serviceResourceSkill.EffectiveEndDate = Date.today();
                }
            }

            newServiceResourceSkills.add(serviceResourceSkill);
        }

        upsert newServiceResourceSkills;
        //upsert , sjekker at du har id, og oppdatere og inserter samtidig.  sjekk det opp.
        // refreshapex
    }
    //     @AuraEnabled
    //     public static void updateServiceResourceSkill(ServiceResource serviceResource, List<Skill> skill) {
    //         serviceResourceSkill.EffectiveEndDate = Date.today();
    //         //Ikke i en for-loop. insert listen samtidig.
    //         insert serviceResourceSkill;
    //         // insert new List<serviceResourceSkill>{ formidler1, formidler2 };
    // }

    // refreshapex
}
